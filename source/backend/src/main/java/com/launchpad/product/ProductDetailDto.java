package com.launchpad.product;

import com.launchpad.topic.TopicDto;
import java.time.LocalDate;
import java.util.List;

public record ProductDetailDto(
		Long id,
		String name,
		String tagline,
		String description,
		String logoUrl,
		String websiteUrl,
		LocalDate launchDate,
		List<TopicDto> topics,
		List<ProductScreenshotDto> screenshots) {
}
