package com.Rahul.AshaSathi;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableAsync;

@SpringBootApplication
@EnableAsync
public class AshaSathiApplication {

	public static void main(String[] args) {
		SpringApplication.run(AshaSathiApplication.class, args);
	}

}
