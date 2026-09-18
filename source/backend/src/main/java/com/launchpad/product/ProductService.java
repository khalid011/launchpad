package com.launchpad.product;

import com.launchpad.topic.Topic;
import com.launchpad.topic.TopicDto;
import java.time.LocalDate;
import java.util.Collection;
import java.util.List;
import java.util.Optional;
import org.springframework.stereotype.Service;

@Service
public class ProductService {

	private final ProductRepository productRepository;

	public ProductService(ProductRepository productRepository) {
		this.productRepository = productRepository;
	}

	public List<ProductSummaryDto> listLaunchedProducts() {
		LocalDate today = LocalDate.now();
		return productRepository.findByLaunchDateLessThanEqualOrderByLaunchDateDescIdDesc(today)
				.stream()
				.map(ProductService::toSummaryDto)
				.toList();
	}

	public Optional<ProductDetailDto> getLaunchedProduct(Long id) {
		LocalDate today = LocalDate.now();
		return productRepository.findByIdAndLaunchDateLessThanEqual(id, today)
				.map(ProductService::toDetailDto);
	}

	private static ProductSummaryDto toSummaryDto(Product product) {
		return new ProductSummaryDto(
				product.getId(),
				product.getName(),
				product.getTagline(),
				product.getLogoUrl(),
				product.getLaunchDate(),
				toTopicDtos(product.getTopics()));
	}

	private static ProductDetailDto toDetailDto(Product product) {
		return new ProductDetailDto(
				product.getId(),
				product.getName(),
				product.getTagline(),
				product.getDescription(),
				product.getLogoUrl(),
				product.getWebsiteUrl(),
				product.getLaunchDate(),
				toTopicDtos(product.getTopics()),
				toScreenshotDtos(product.getScreenshots()));
	}

	private static List<TopicDto> toTopicDtos(Collection<Topic> topics) {
		return topics.stream()
				.map(topic -> new TopicDto(topic.getId(), topic.getName(), topic.getSlug()))
				.toList();
	}

	private static List<ProductScreenshotDto> toScreenshotDtos(Collection<ProductScreenshot> screenshots) {
		return screenshots.stream()
				.map(screenshot -> new ProductScreenshotDto(
						screenshot.getId(), screenshot.getUrl(), screenshot.getDisplayOrder()))
				.toList();
	}
}
