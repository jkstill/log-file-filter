
package main


// go build lgwr-switch-time.go

import (
	"bufio"
	"fmt"
	"os"
	// "strconv"
	"strings"
	"time"
)

const (
	maxSwitches     = 1000000
	bucketBoundary  = 50
	dateFormat      = "2006-01-02T15:04:05.999999-07:00"
	timeLayout      = "2006-01-02T15:04:05.999999-07:00"
)

func parseDate(dateStr string) (time.Time, error) {
	t, err := time.Parse(timeLayout, dateStr)
	if err != nil {
		return time.Time{}, err
	}
	return t, nil
}

func main() {
	switchAry := make([]time.Time, 0, maxSwitches)

	scanner := bufio.NewScanner(os.Stdin)
	prevLine := ""
	for scanner.Scan() {
		line := scanner.Text()
		if strings.Contains(line, "LGWR switch") {
			t, err := parseDate(prevLine)
			if err != nil {
				fmt.Fprintf(os.Stderr, "Error parsing date: %v\n", err)
				os.Exit(1)
			}
			switchAry = append(switchAry, t)
		}
		prevLine = line
	}

	if err := scanner.Err(); err != nil {
		fmt.Fprintf(os.Stderr, "Error reading input: %v\n", err)
		os.Exit(1)
	}

	maxKey := len(switchAry) - 1

	for key := 1; key <= maxKey; key++ {
		delta := switchAry[key].Sub(switchAry[key-1])
		delta = delta - (delta % time.Duration(bucketBoundary)*time.Second)
		fmt.Println(int64(delta.Seconds()))
	}
}

