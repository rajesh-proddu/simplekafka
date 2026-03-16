package main

import (
	"fmt"
	"os"
)

func main() {
	if len(os.Args) < 2 {
		fmt.Println("SimpleKafka - Kafka Producer and Consumer in Go")
		fmt.Println("")
		fmt.Println("This is a workspace module. Build and run specific applications:")
		fmt.Println("")
		fmt.Println("  Producer:")
		fmt.Println("    cd producer && go build -o producer . && ./producer")
		fmt.Println("")
		fmt.Println("  Consumer:")
		fmt.Println("    cd consumer && go build -o consumer . && ./consumer")
		fmt.Println("")
		fmt.Println("Or use Docker Compose for quick start:")
		fmt.Println("  docker-compose up")
		fmt.Println("")
		fmt.Println("Or use Make:")
		fmt.Println("  make compose-up")
		os.Exit(0)
	}
}
