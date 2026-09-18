package com.launchpad.product;

import com.launchpad.topic.Topic;
import jakarta.persistence.CollectionTable;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.JoinTable;
import jakarta.persistence.ManyToMany;
import jakarta.persistence.OneToMany;
import jakarta.persistence.OrderBy;
import jakarta.persistence.Table;
import java.time.Instant;
import java.time.LocalDate;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;

@Entity
@Table(name = "products")
public class Product {

	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	private Long id;

	private String name;
	private String tagline;
	private String description;
	private String logoUrl;
	private String websiteUrl;
	private LocalDate launchDate;
	private Instant createdAt;
	private Instant updatedAt;

	@ManyToMany
	@JoinTable(
		name = "product_topics",
		joinColumns = @JoinColumn(name = "product_id"),
		inverseJoinColumns = @JoinColumn(name = "topic_id")
	)
	private Set<Topic> topics = new LinkedHashSet<>();

	@OneToMany(mappedBy = "product")
	@OrderBy("displayOrder")
	private List<ProductScreenshot> screenshots;

	protected Product() {
	}

	public Product(String name, String tagline, String description, String logoUrl,
			String websiteUrl, LocalDate launchDate) {
		this.name = name;
		this.tagline = tagline;
		this.description = description;
		this.logoUrl = logoUrl;
		this.websiteUrl = websiteUrl;
		this.launchDate = launchDate;
	}

	public Long getId() {
		return id;
	}

	public String getName() {
		return name;
	}

	public String getTagline() {
		return tagline;
	}

	public String getDescription() {
		return description;
	}

	public String getLogoUrl() {
		return logoUrl;
	}

	public String getWebsiteUrl() {
		return websiteUrl;
	}

	public LocalDate getLaunchDate() {
		return launchDate;
	}

	public Instant getCreatedAt() {
		return createdAt;
	}

	public Instant getUpdatedAt() {
		return updatedAt;
	}

	public Set<Topic> getTopics() {
		return topics;
	}

	public List<ProductScreenshot> getScreenshots() {
		return screenshots;
	}
}
