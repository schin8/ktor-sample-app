package com.example

import io.ktor.server.application.*
import org.slf4j.LoggerFactory


fun main(args: Array<String>) {
    io.ktor.server.netty.EngineMain.main(args)
}

fun Application.module() {
    // Create a custom logger
    val logger = LoggerFactory.getLogger("Application")
    
    // Add a custom startup message
    environment.monitor.subscribe(ApplicationStarted) {
        val port = environment.config.propertyOrNull("ktor.deployment.port")?.getString() ?: "8080"
        logger.info("Server started successfully! Visit http://localhost:$port")
    }

    configureRouting()
}
