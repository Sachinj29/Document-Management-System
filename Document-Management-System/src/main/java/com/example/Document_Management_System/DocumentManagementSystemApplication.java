//package com.example.Document_Management_System;
//
//import org.springframework.boot.SpringApplication;
//import org.springframework.boot.autoconfigure.SpringBootApplication;
//
//@SpringBootApplication
//public class DocumentManagementSystemApplication {
//
//	public static void main(String[] args) {
//		SpringApplication.run(DocumentManagementSystemApplication.class, args);
//	}
//
//}


package com.example.Document_Management_System;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableAsync;
import org.springframework.scheduling.annotation.EnableScheduling;
import org.springframework.transaction.annotation.EnableTransactionManagement;

@SpringBootApplication
@EnableAsync
@EnableScheduling
@EnableTransactionManagement
public class DocumentManagementSystemApplication {

	public static void main(String[] args) {
		SpringApplication.run(DocumentManagementSystemApplication.class, args);
		System.out.println("Run Successfuly");
	}
}
