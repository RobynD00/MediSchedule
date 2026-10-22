package com.medischedule.backend.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.scheduling.annotation.EnableScheduling;

/** Switches on @Scheduled jobs. Its own file so BackendApplication stays untouched. */
@Configuration
@EnableScheduling
public class SchedulingConfig {
}
