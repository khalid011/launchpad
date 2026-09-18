package com.launchpad.product;

import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;

@Entity
@Table(name = "product_screenshots")
public class ProductScreenshot {

	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	private Long id;

	@ManyToOne
	@JoinColumn(name = "product_id")
	private Product product;

	private String url;

	private Integer displayOrder;

	protected ProductScreenshot() {
	}

	public ProductScreenshot(Product product, String url, Integer displayOrder) {
		this.product = product;
		this.url = url;
		this.displayOrder = displayOrder;
	}

	public Long getId() {
		return id;
	}

	public Product getProduct() {
		return product;
	}

	public String getUrl() {
		return url;
	}

	public Integer getDisplayOrder() {
		return displayOrder;
	}
}
