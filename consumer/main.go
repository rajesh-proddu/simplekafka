package main

import (
	"context"
	"log"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/segmentio/kafka-go"
)

func main() {
	// Configuration from environment variables
	brokers := getEnv("KAFKA_BROKERS", "localhost:9092")
	topic := getEnv("KAFKA_TOPIC", "test-topic")
	groupID := getEnv("KAFKA_GROUP_ID", "consumer-group-1")

	log.Printf("Consumer starting - Brokers: %s, Topic: %s, Group: %s", brokers, topic, groupID)

	// Create reader
	reader := kafka.NewReader(kafka.ReaderConfig{
		Brokers:        []string{brokers},
		Topic:          topic,
		GroupID:        groupID,
		CommitInterval: time.Second,
		StartOffset:    kafka.LastOffset,
		MaxBytes:       1e6,
		SessionTimeout: 30 * time.Second,
		ReadBackoffMin: 100 * time.Millisecond,
		ReadBackoffMax: 1 * time.Second,
		QueueCapacity:  100,
	})
	defer reader.Close()

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	// Handle graceful shutdown
	sigChan := make(chan os.Signal, 1)
	signal.Notify(sigChan, syscall.SIGINT, syscall.SIGTERM)

	go func() {
		<-sigChan
		log.Println("Shutdown signal received")
		cancel()
	}()

	// Consume messages
	messagesReceived := 0
	for {
		select {
		case <-ctx.Done():
			log.Printf("Consumer stopped - Total messages received: %d", messagesReceived)
			return
		default:
			message, err := reader.ReadMessage(ctx)
			if err != nil {
				if err == context.Canceled {
					log.Printf("Consumer stopped - Total messages received: %d", messagesReceived)
					return
				}
				log.Printf("Error reading message: %v", err)
				continue
			}

			messagesReceived++
			log.Printf("Received - Partition: %d, Offset: %d, Key: %s, Value: %s, Timestamp: %s",
				message.Partition, message.Offset, message.Key, message.Value, message.Time.Format(time.RFC3339))
		}
	}
}

func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}
