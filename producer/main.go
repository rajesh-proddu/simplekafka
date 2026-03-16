package main

import (
	"context"
	"fmt"
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
	messageCount := getEnvInt("MESSAGE_COUNT", 10)
	messageInterval := getEnvInt("MESSAGE_INTERVAL", 1000) // milliseconds

	log.Printf("Producer starting - Brokers: %s, Topic: %s", brokers, topic)

	// Create writer
	writer := kafka.NewWriter(kafka.WriterConfig{
		Brokers:      []string{brokers},
		Topic:        topic,
		Balancer:     &kafka.LeastBytes{},
		WriteTimeout: 10 * time.Second,
		ReadTimeout:  10 * time.Second,
	})
	defer writer.Close()

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

	// Send messages
	messagesSent := 0
	ticker := time.NewTicker(time.Duration(messageInterval) * time.Millisecond)
	defer ticker.Stop()

	for i := 0; i < messageCount; i++ {
		select {
		case <-ctx.Done():
			log.Println("Producer stopped")
			return
		case <-ticker.C:
			message := kafka.Message{
				Key:   []byte(fmt.Sprintf("key-%d", i)),
				Value: []byte(fmt.Sprintf("Message %d at %s", i, time.Now().Format(time.RFC3339))),
			}

			err := writer.WriteMessages(ctx, message)
			if err != nil {
				log.Printf("Error writing message: %v", err)
				continue
			}

			messagesSent++
			log.Printf("Sent message %d/%d - Key: %s", messagesSent, messageCount, message.Key)
		}
	}

	// Wait a bit for final messages to be flushed
	log.Println("All messages sent, waiting for flush...")
	time.Sleep(2 * time.Second)
	log.Printf("Producer finished - Total messages sent: %d", messagesSent)
}

func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}

func getEnvInt(key string, defaultValue int) int {
	if value := os.Getenv(key); value != "" {
		var intVal int
		fmt.Sscanf(value, "%d", &intVal)
		return intVal
	}
	return defaultValue
}
