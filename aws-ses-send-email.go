package main

import (
	"crypto/tls"
	"fmt"
	"log"
	"net/smtp"
	"os"
)

func main() {
	recipient := os.Args[1]
	smtpUsername := "ses username"
	smtpPassword := "ses password"
	smtpHost := "email-smtp.us-west-2.amazonaws.com"
	smtpPort := "2587"

	// Setup authentication
	auth := smtp.PlainAuth("", smtpUsername, smtpPassword, smtpHost)

	// connect to server, but don't use TLS yet
	client, err := smtp.Dial(smtpHost + ":" + smtpPort)
	if err != nil {
		log.Fatal(err)
	}

	// TLS config
	tlsConfig := &tls.Config{
		InsecureSkipVerify: false,
		ServerName:         smtpHost,
	}
	t
	client.StartTLS(tlsConfig)

	// authenticate
	if err = client.Auth(auth); err != nil {
		log.Fatal(err)
	}

	// set sender and recipient
	from := "no_reply@mail.yourdomain.com"
	to := recipient

	// set email headers and body
	headers := make(map[string]string)
	headers["From"] = from
	headers["To"] = to
	headers["Subject"] = "An email from AWS SES"
	body := "This is an email from no_reply@mail.yourdomain.com using AWS SES SMTP. \nSender: Best Regards"

	// compose the message
	message := ""
	for k, v := range headers {
		message += fmt.Sprintf("%s: %s\r\n", k, v)
	}
	message += "\r\n + body"

	// sending email
	if err = client.Mail(from); err != nil {
		log.Fatal(err)
	}
	if err = client.Rcpt(to); err != nil {
		log.Fatal(err)
	}

	w, err := client.Data()
	if err != nil {
		log.Fatal(err)
	}
	_, err = w.Write([]byte(message))
	if err != nil {
		log.Fatal(err)
	}
	err = w.Close()
	if err != nil {
		log.Fatal(err)
	}

	client.Quit()
	fmt.Println("Email sent successfully")
}
