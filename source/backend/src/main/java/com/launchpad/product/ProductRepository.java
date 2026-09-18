package com.launchpad.product;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;

public interface

ProductRepository extends JpaRepository<Product, Long> {

	// List endpoint: only eager-fetch topics — never screenshots here, to avoid
	// the cartesian-product/pagination trap from the plan review.
	@EntityGraph(attributePaths = "topics")
	List<Product> findByLaunchDateLessThanEqualOrderByLaunchDateDescIdDesc(LocalDate today);

	// Detail endpoint: eager-fetch only topics here too. Eagerly joining topics AND
	// screenshots together (even for a single row) produces one SQL row per
	// (topic, screenshot) combination — a real cartesian-product duplication bug,
	// not just a pagination one. Screenshots lazy-load instead: for a single product
	// that's one harmless extra query, not the N+1-across-a-list problem this
	// eager-fetching strategy exists to avoid in the first place.
	// Also embargo-filtered, so an unlaunched id behaves the same as a nonexistent one.
	@EntityGraph(attributePaths = "topics")
	Optional<Product> findByIdAndLaunchDateLessThanEqual(Long id, LocalDate today);
}
