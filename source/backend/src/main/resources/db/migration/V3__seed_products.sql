-- Seed products spread across past, today, and future launch dates so both
-- the embargo rule (future-dated products must NOT appear) and its
-- today-launches boundary case (today-dated products MUST appear) can be
-- verified end to end.

INSERT INTO products (name, tagline, description, logo_url, website_url, launch_date) VALUES
    ('Focusly', 'A calm, distraction-free task manager for deep work',
     'Focusly strips away notifications, badges, and clutter so you can plan your day around a handful of things that actually matter, then get out of your own way.',
     'https://placehold.co/128x128?text=Focusly', 'https://focusly.example.com', CURRENT_DATE - INTERVAL '10 days'),

    ('PixelPitch', 'Turn plain screenshots into polished product demos in seconds',
     'Drop in a screenshot, pick a backdrop and browser frame, and PixelPitch renders a launch-ready image or GIF you can drop straight into a landing page.',
     'https://placehold.co/128x128?text=PixelPitch', 'https://pixelpitch.example.com', CURRENT_DATE - INTERVAL '5 days'),

    ('Gitline', 'Pull request review that actually fits how your team reviews code',
     'Gitline groups review comments by intent, tracks who still owes a review, and nudges reviewers before a PR goes stale instead of after.',
     'https://placehold.co/128x128?text=Gitline', 'https://gitline.example.com', CURRENT_DATE - INTERVAL '3 days'),

    ('Nudge', 'A habit tracker that adapts when you miss a day, instead of shaming you',
     'Nudge quietly reshuffles your streaks around real life, so one missed morning run does not blow up three months of consistency.',
     'https://placehold.co/128x128?text=Nudge', 'https://nudge.example.com', CURRENT_DATE - INTERVAL '2 days'),

    ('LoopMail', 'Smart inbox triage for people who get too much email',
     'LoopMail learns which threads you actually reply to and quietly archives the rest into a weekly digest instead of your inbox.',
     'https://placehold.co/128x128?text=LoopMail', 'https://loopmail.example.com', CURRENT_DATE - INTERVAL '1 day'),

    ('Wispr', 'AI meeting summaries that capture decisions, not just transcripts',
     'Wispr listens in, then hands you three bullet points: what was decided, who owns what, and what is still open — no 40-minute transcript to skim.',
     'https://placehold.co/128x128?text=Wispr', 'https://wispr.example.com', CURRENT_DATE),

    ('Ledgerly', 'Invoicing and expense tracking built for solo freelancers',
     'Ledgerly sends invoices, chases late payments politely, and sorts expenses into tax categories automatically — no accounting background required.',
     'https://placehold.co/128x128?text=Ledgerly', 'https://ledgerly.example.com', CURRENT_DATE),

    ('Codex Notes', 'Documentation search that understands your actual codebase',
     'Codex Notes indexes your repo alongside your docs, so a search for a function name surfaces the explanation next to the code that implements it.',
     'https://placehold.co/128x128?text=Codex+Notes', 'https://codexnotes.example.com', CURRENT_DATE),

    ('Brandkit', 'Generate a logo, color palette, and style guide in one sitting',
     'Answer a handful of questions about your product, and Brandkit produces a starter logo, palette, and one-page style guide to launch with.',
     'https://placehold.co/128x128?text=Brandkit', 'https://brandkit.example.com', CURRENT_DATE + INTERVAL '1 day'),

    ('Quizzy', 'A quiz maker built for classroom teachers, not marketers',
     'Quizzy skips the lead-capture gimmicks aimed at marketers and focuses on what a teacher actually needs: quick quizzes, auto-grading, and clear results.',
     'https://placehold.co/128x128?text=Quizzy', 'https://quizzy.example.com', CURRENT_DATE + INTERVAL '3 days'),

    ('PixelPlay', 'A discovery feed for indie games that are still in development',
     'PixelPlay surfaces indie games while they are being built, so players can follow along and wishlist early instead of discovering a game after launch.',
     'https://placehold.co/128x128?text=PixelPlay', 'https://pixelplay.example.com', CURRENT_DATE + INTERVAL '5 days'),

    ('FormFlow', 'A drag-and-drop form builder with a real API behind every form',
     'FormFlow builds forms visually but treats every field as a typed API field from the start, so exporting to your own backend is a copy-paste away.',
     'https://placehold.co/128x128?text=FormFlow', 'https://formflow.example.com', CURRENT_DATE + INTERVAL '7 days');

-- Topics (up to 3 per product, respecting the cap even though it's not yet enforced)

INSERT INTO product_topics (product_id, topic_id)
SELECT p.id, t.id FROM products p, topics t WHERE p.name = 'Focusly'     AND t.slug IN ('productivity', 'ai');
INSERT INTO product_topics (product_id, topic_id)
SELECT p.id, t.id FROM products p, topics t WHERE p.name = 'PixelPitch'  AND t.slug IN ('design-tools', 'marketing');
INSERT INTO product_topics (product_id, topic_id)
SELECT p.id, t.id FROM products p, topics t WHERE p.name = 'Gitline'    AND t.slug IN ('developer-tools');
INSERT INTO product_topics (product_id, topic_id)
SELECT p.id, t.id FROM products p, topics t WHERE p.name = 'Nudge'      AND t.slug IN ('productivity', 'health-fitness');
INSERT INTO product_topics (product_id, topic_id)
SELECT p.id, t.id FROM products p, topics t WHERE p.name = 'LoopMail'   AND t.slug IN ('productivity', 'ai');
INSERT INTO product_topics (product_id, topic_id)
SELECT p.id, t.id FROM products p, topics t WHERE p.name = 'Wispr'      AND t.slug IN ('ai', 'saas');
INSERT INTO product_topics (product_id, topic_id)
SELECT p.id, t.id FROM products p, topics t WHERE p.name = 'Ledgerly'   AND t.slug IN ('fintech', 'saas');
INSERT INTO product_topics (product_id, topic_id)
SELECT p.id, t.id FROM products p, topics t WHERE p.name = 'Codex Notes' AND t.slug IN ('developer-tools', 'ai');
INSERT INTO product_topics (product_id, topic_id)
SELECT p.id, t.id FROM products p, topics t WHERE p.name = 'Brandkit'   AND t.slug IN ('design-tools', 'marketing');
INSERT INTO product_topics (product_id, topic_id)
SELECT p.id, t.id FROM products p, topics t WHERE p.name = 'Quizzy'     AND t.slug IN ('education');
INSERT INTO product_topics (product_id, topic_id)
SELECT p.id, t.id FROM products p, topics t WHERE p.name = 'PixelPlay'  AND t.slug IN ('games', 'marketing');
INSERT INTO product_topics (product_id, topic_id)
SELECT p.id, t.id FROM products p, topics t WHERE p.name = 'FormFlow'   AND t.slug IN ('productivity', 'saas', 'developer-tools');

-- Screenshots (2-3 per product, distinct display_order to verify ordering)

INSERT INTO product_screenshots (product_id, url, display_order)
SELECT id, 'https://placehold.co/800x500?text=' || replace(name, ' ', '+') || '+Screenshot+1', 0 FROM products;
INSERT INTO product_screenshots (product_id, url, display_order)
SELECT id, 'https://placehold.co/800x500?text=' || replace(name, ' ', '+') || '+Screenshot+2', 1 FROM products;
INSERT INTO product_screenshots (product_id, url, display_order)
SELECT id, 'https://placehold.co/800x500?text=' || replace(name, ' ', '+') || '+Screenshot+3', 2
FROM products WHERE name IN ('Focusly', 'Wispr', 'Codex Notes', 'FormFlow');
