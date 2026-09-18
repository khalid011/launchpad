package com.launchpad.product;

import com.launchpad.topic.TopicDto;
import java.time.LocalDate;
import java.util.List;

public record ProductSummaryDto(
		Long id,
		String name,
		String tagline,
		String logoUrl,
		LocalDate launchDate,
		List<TopicDto> topics) {
}
