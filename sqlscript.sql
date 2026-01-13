-- ============================================================================
-- 53 COX ROAD GALLERY - COMPLETE DATABASE SCHEMA (DDL)
-- Generated: 2025-12-26
-- Total Tables: 67
-- Includes: Tables, Indexes, Triggers, and Functions
-- ============================================================================

-- ============================================================================
-- TRIGGER FUNCTIONS
-- ============================================================================

-- Function to update the updated_date timestamp



CREATE TABLE IF NOT EXISTS users (
    id VARCHAR PRIMARY KEY,
    full_name VARCHAR NOT NULL,
    email VARCHAR UNIQUE NOT NULL,
    role VARCHAR NOT NULL,
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    password VARCHAR(255),
    CONSTRAINT users_role_check CHECK (role IN ('admin', 'user'))
);



CREATE OR REPLACE FUNCTION update_updated_date_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_date = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Add the trigger for updated_date
CREATE TRIGGER update_users_updated_date
    BEFORE UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_date_column();
-- Function to sync follower count when artist_follows changes
CREATE OR REPLACE FUNCTION sync_artist_follower_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE artists SET follower_count = follower_count + 1 WHERE id = NEW.artist_id;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE artists SET follower_count = follower_count - 1 WHERE id = OLD.artist_id;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Function to sync event tickets sold count
CREATE OR REPLACE FUNCTION sync_event_tickets_sold()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE events SET tickets_sold = tickets_sold + NEW.number_of_tickets WHERE id = NEW.event_id;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE events SET tickets_sold = tickets_sold - OLD.number_of_tickets WHERE id = OLD.event_id;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Function to sync auction bid count
CREATE OR REPLACE FUNCTION sync_auction_bid_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE auctions
        SET total_bids = total_bids + 1,
            current_bid = NEW.bid_amount
        WHERE id = NEW.auction_id;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Function to update workshop session booked slots
CREATE OR REPLACE FUNCTION sync_workshop_booked_slots()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE workshop_sessions
        SET booked_slots = booked_slots + NEW.number_of_tickets
        WHERE id = NEW.session_id;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE workshop_sessions
        SET booked_slots = booked_slots - OLD.number_of_tickets
        WHERE id = OLD.session_id;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Function to sync collection likes count
CREATE OR REPLACE FUNCTION sync_collection_likes_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE collections SET likes_count = likes_count + 1 WHERE id = NEW.collection_id;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE collections SET likes_count = likes_count - 1 WHERE id = OLD.collection_id;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- TABLES, INDEXES, AND TRIGGERS
-- ============================================================================


ALTER TABLE IF EXISTS users
    OWNER to postgres;
-- Index: idx_users_created_date

-- DROP INDEX IF EXISTS idx_users_created_date;

CREATE INDEX IF NOT EXISTS idx_users_created_date
    ON users USING btree
    (created_date DESC NULLS FIRST)
    TABLESPACE pg_default;
-- Index: idx_users_email

-- DROP INDEX IF EXISTS idx_users_email;

CREATE INDEX IF NOT EXISTS idx_users_email
    ON users USING btree
    (email COLLATE pg_catalog."default" ASC NULLS LAST)
    TABLESPACE pg_default;
-- Index: idx_users_role

-- DROP INDEX IF EXISTS idx_users_role;

CREATE INDEX IF NOT EXISTS idx_users_role
    ON users USING btree
    (role COLLATE pg_catalog."default" ASC NULLS LAST)
    TABLESPACE pg_default;

-- Trigger: update_users_updated_date

-- DROP TRIGGER IF EXISTS update_users_updated_date ON users;

CREATE OR REPLACE TRIGGER update_users_updated_date
    BEFORE UPDATE 
    ON users
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_date_column();



-- 1. GARDENS
CREATE TABLE gardens (
    id VARCHAR PRIMARY KEY,
    name VARCHAR NOT NULL,
    description TEXT,
    image_url VARCHAR,
    capacity INTEGER,
    hourly_rate DECIMAL(10,2),
    reservation_fee DECIMAL(10,2),
    features TEXT[],
    available_hours TEXT[],
    is_available BOOLEAN DEFAULT true,
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR
);

CREATE INDEX idx_gardens_available ON gardens(is_available);
CREATE INDEX idx_gardens_created_date ON gardens(created_date DESC);

CREATE TRIGGER update_gardens_updated_date
    BEFORE UPDATE ON gardens
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_date_column();

-- 2. GARDEN BOOKINGS
CREATE TABLE garden_bookings (
    id VARCHAR PRIMARY KEY,
    garden_id VARCHAR,
    garden_name VARCHAR,
    date DATE NOT NULL,
    start_time VARCHAR,
    end_time VARCHAR,
    duration_hours DECIMAL(4,2),
    guest_count INTEGER,
    booker_name VARCHAR NOT NULL,
    booker_email VARCHAR NOT NULL,
    booker_phone VARCHAR,
    purpose VARCHAR,
    special_requests TEXT,
    reservation_fee DECIMAL(10,2),
    total_price DECIMAL(10,2),
    payment_status VARCHAR DEFAULT 'pending',
    payment_date VARCHAR,
    status VARCHAR DEFAULT 'pending',
    cancellation_date VARCHAR,
    cancellation_fee_charged DECIMAL(10,2),
    is_rain_affected BOOLEAN DEFAULT false,
    rain_marked_date VARCHAR,
    rain_resolution VARCHAR,
    rebooked_from_id VARCHAR,
    rebooked_to_id VARCHAR,
    refund_amount DECIMAL(10,2),
    refund_date VARCHAR,
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR
);

CREATE INDEX idx_garden_bookings_date ON garden_bookings(date);
CREATE INDEX idx_garden_bookings_garden_id ON garden_bookings(garden_id);
CREATE INDEX idx_garden_bookings_email ON garden_bookings(booker_email);
CREATE INDEX idx_garden_bookings_status ON garden_bookings(status);
CREATE INDEX idx_garden_bookings_created_by ON garden_bookings(created_by);

CREATE TRIGGER update_garden_bookings_updated_date
    BEFORE UPDATE ON garden_bookings
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_date_column();

-- 3. PAINTING STATION BOOKINGS
CREATE TABLE painting_station_bookings (
    id VARCHAR PRIMARY KEY,
    booking_type VARCHAR NOT NULL,
    date DATE NOT NULL,
    time_slot VARCHAR NOT NULL,
    station_numbers INTEGER[],
    participant_count INTEGER DEFAULT 1,
    booker_name VARCHAR NOT NULL,
    booker_email VARCHAR NOT NULL,
    booker_phone VARCHAR,
    company_name VARCHAR,
    converted_to_family BOOLEAN DEFAULT false,
    conversion_date VARCHAR,
    converted_by VARCHAR,
    per_person_rate DECIMAL(10,2),
    use_own_materials BOOLEAN DEFAULT false,
    materials_description TEXT,
    materials_approval_status VARCHAR DEFAULT 'pending',
    special_requests TEXT,
    reservation_fee DECIMAL(10,2),
    price DECIMAL(10,2),
    payment_status VARCHAR DEFAULT 'pending',
    payment_date VARCHAR,
    status VARCHAR DEFAULT 'pending',
    cancellation_date VARCHAR,
    cancellation_fee_charged DECIMAL(10,2),
    is_rain_affected BOOLEAN DEFAULT false,
    rain_marked_date VARCHAR,
    rain_resolution VARCHAR,
    rebooked_from_id VARCHAR,
    rebooked_to_id VARCHAR,
    refund_amount DECIMAL(10,2),
    refund_date VARCHAR,
    duration_hours DECIMAL(4,2) DEFAULT 2,
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR
);

CREATE INDEX idx_painting_bookings_date ON painting_station_bookings(date);
CREATE INDEX idx_painting_bookings_time ON painting_station_bookings(time_slot);
CREATE INDEX idx_painting_bookings_email ON painting_station_bookings(booker_email);
CREATE INDEX idx_painting_bookings_status ON painting_station_bookings(status);
CREATE INDEX idx_painting_bookings_type ON painting_station_bookings(booking_type);
CREATE INDEX idx_painting_bookings_created_by ON painting_station_bookings(created_by);

CREATE TRIGGER update_painting_bookings_updated_date
    BEFORE UPDATE ON painting_station_bookings
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_date_column();

-- 4. GIFT VOUCHERS
CREATE TABLE gift_vouchers (
    id VARCHAR PRIMARY KEY,
    voucher_code VARCHAR UNIQUE NOT NULL,
    voucher_type VARCHAR NOT NULL,
    amount DECIMAL(10,2),
    experience_type VARCHAR,
    purchaser_name VARCHAR NOT NULL,
    purchaser_email VARCHAR NOT NULL,
    recipient_name VARCHAR,
    recipient_email VARCHAR NOT NULL,
    personal_message TEXT,
    purchase_price DECIMAL(10,2) NOT NULL,
    status VARCHAR DEFAULT 'active',
    redeemed_by VARCHAR,
    redeemed_date VARCHAR,
    booking_id VARCHAR,
    expiry_date DATE,
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR
);

CREATE INDEX idx_vouchers_code ON gift_vouchers(voucher_code);
CREATE INDEX idx_vouchers_status ON gift_vouchers(status);
CREATE INDEX idx_vouchers_recipient ON gift_vouchers(recipient_email);
CREATE INDEX idx_vouchers_purchaser ON gift_vouchers(purchaser_email);
CREATE INDEX idx_vouchers_expiry ON gift_vouchers(expiry_date);

CREATE TRIGGER update_vouchers_updated_date
    BEFORE UPDATE ON gift_vouchers
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_date_column();

-- 5. ARTISTS
CREATE TABLE artists (
    id VARCHAR PRIMARY KEY,
    name VARCHAR NOT NULL,
    bio TEXT,
    profile_image VARCHAR,
    cover_image VARCHAR,
    specialties TEXT[],
    location VARCHAR,
    website VARCHAR,
    instagram VARCHAR,
    statement TEXT,
    is_featured BOOLEAN DEFAULT false,
    is_available BOOLEAN DEFAULT true,
    follower_count INTEGER DEFAULT 0,
    commission_base_price DECIMAL(10,2),
    accepts_messages BOOLEAN DEFAULT true,
    accepts_donations BOOLEAN DEFAULT true,
    donation_url VARCHAR,
    user_email VARCHAR,
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR
);

CREATE INDEX idx_artists_name ON artists(name);
CREATE INDEX idx_artists_featured ON artists(is_featured);
CREATE INDEX idx_artists_available ON artists(is_available);
CREATE INDEX idx_artists_user_email ON artists(user_email);
CREATE INDEX idx_artists_followers ON artists(follower_count DESC);

CREATE TRIGGER update_artists_updated_date
    BEFORE UPDATE ON artists
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_date_column();

-- 6. ARTIST FOLLOWS
CREATE TABLE artist_follows (
    id VARCHAR PRIMARY KEY,
    artist_id VARCHAR NOT NULL,
    follower_email VARCHAR NOT NULL,
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR,
    UNIQUE(artist_id, follower_email)
);

CREATE INDEX idx_artist_follows_artist ON artist_follows(artist_id);
CREATE INDEX idx_artist_follows_follower ON artist_follows(follower_email);

CREATE TRIGGER update_artist_follows_updated_date
    BEFORE UPDATE ON artist_follows
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_date_column();

CREATE TRIGGER sync_artist_followers_insert
    AFTER INSERT ON artist_follows
    FOR EACH ROW
    EXECUTE FUNCTION sync_artist_follower_count();

CREATE TRIGGER sync_artist_followers_delete
    AFTER DELETE ON artist_follows
    FOR EACH ROW
    EXECUTE FUNCTION sync_artist_follower_count();

-- 7. ARTIST MESSAGES
CREATE TABLE artist_messages (
    id VARCHAR PRIMARY KEY,
    artist_id VARCHAR NOT NULL,
    artist_name VARCHAR,
    sender_name VARCHAR NOT NULL,
    sender_email VARCHAR NOT NULL,
    subject VARCHAR,
    message TEXT NOT NULL,
    status VARCHAR DEFAULT 'sent',
    reply TEXT,
    replied_at VARCHAR,
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR
);

CREATE INDEX idx_artist_messages_artist ON artist_messages(artist_id);
CREATE INDEX idx_artist_messages_sender ON artist_messages(sender_email);
CREATE INDEX idx_artist_messages_status ON artist_messages(status);
CREATE INDEX idx_artist_messages_created ON artist_messages(created_date DESC);

CREATE TRIGGER update_artist_messages_updated_date
    BEFORE UPDATE ON artist_messages
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_date_column();

-- 8. ARTWORKS
CREATE TABLE artworks (
    id VARCHAR PRIMARY KEY,
    title VARCHAR NOT NULL,
    artist VARCHAR NOT NULL,
    description TEXT,
    price DECIMAL(10,2) NOT NULL,
    currency VARCHAR DEFAULT 'AUD',
    is_in_stock BOOLEAN DEFAULT true,
    image_url VARCHAR,
    garden_origin VARCHAR,
    art_style VARCHAR,
    dimensions VARCHAR,
    year_created INTEGER,
    featured BOOLEAN DEFAULT false,
    nar_registry_number VARCHAR NOT NULL,
    nar_registered_date DATE,
    allow_reprints BOOLEAN DEFAULT false,
    reprint_price DECIMAL(10,2),
    max_reprints INTEGER,
    reprints_sold INTEGER DEFAULT 0,
    is_original BOOLEAN DEFAULT true,
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR
);

CREATE INDEX idx_artworks_artist ON artworks(artist);
CREATE INDEX idx_artworks_featured ON artworks(featured);
CREATE INDEX idx_artworks_in_stock ON artworks(is_in_stock);
CREATE INDEX idx_artworks_style ON artworks(art_style);
CREATE INDEX idx_artworks_price ON artworks(price);
CREATE INDEX idx_artworks_nar ON artworks(nar_registry_number);
CREATE INDEX idx_artworks_created ON artworks(created_date DESC);

CREATE TRIGGER update_artworks_updated_date
    BEFORE UPDATE ON artworks
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_date_column();

-- 9. CART
CREATE TABLE cart (
    id VARCHAR PRIMARY KEY,
    artwork_id VARCHAR,
    merchandise_id VARCHAR,
    quantity INTEGER DEFAULT 1,
    price_at_addition DECIMAL(10,2),
    selected_size VARCHAR,
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR
);

CREATE INDEX idx_cart_created_by ON cart(created_by);
CREATE INDEX idx_cart_artwork ON cart(artwork_id);
CREATE INDEX idx_cart_merchandise ON cart(merchandise_id);

CREATE TRIGGER update_cart_updated_date
    BEFORE UPDATE ON cart
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_date_column();

-- 10. ORDERS
CREATE TABLE orders (
    id VARCHAR PRIMARY KEY,
    items JSONB NOT NULL,
    total_price DECIMAL(10,2) NOT NULL,
    currency VARCHAR DEFAULT 'AUD',
    shipping_name VARCHAR NOT NULL,
    shipping_address VARCHAR NOT NULL,
    shipping_city VARCHAR,
    shipping_state VARCHAR,
    shipping_postcode VARCHAR,
    shipping_method VARCHAR DEFAULT 'standard',
    shipping_cost DECIMAL(10,2),
    status VARCHAR DEFAULT 'pending',
    notes TEXT,
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR
);

CREATE INDEX idx_orders_status ON orders(status);
CREATE INDEX idx_orders_created_by ON orders(created_by);
CREATE INDEX idx_orders_created_date ON orders(created_date DESC);

CREATE TRIGGER update_orders_updated_date
    BEFORE UPDATE ON orders
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_date_column();

-- 11. EXHIBITIONS
CREATE TABLE exhibitions (
    id VARCHAR PRIMARY KEY,
    title VARCHAR NOT NULL,
    description TEXT,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    featured_artists TEXT[],
    image_url VARCHAR,
    virtual_tour_url VARCHAR,
    floor_plan_url VARCHAR,
    available_slots JSONB,
    status VARCHAR DEFAULT 'upcoming',
    location VARCHAR,
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR
);

CREATE INDEX idx_exhibitions_status ON exhibitions(status);
CREATE INDEX idx_exhibitions_start_date ON exhibitions(start_date);
CREATE INDEX idx_exhibitions_end_date ON exhibitions(end_date);

CREATE TRIGGER update_exhibitions_updated_date
    BEFORE UPDATE ON exhibitions
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_date_column();

-- 12. EXHIBITION BOOKINGS
CREATE TABLE exhibition_bookings (
    id VARCHAR PRIMARY KEY,
    exhibition_id VARCHAR NOT NULL,
    visitor_name VARCHAR NOT NULL,
    visitor_email VARCHAR NOT NULL,
    visitor_phone VARCHAR,
    preferred_date DATE NOT NULL,
    preferred_time VARCHAR NOT NULL,
    party_size INTEGER DEFAULT 1,
    notes TEXT,
    status VARCHAR DEFAULT 'pending',
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR
);

CREATE INDEX idx_exhibition_bookings_exhibition ON exhibition_bookings(exhibition_id);
CREATE INDEX idx_exhibition_bookings_email ON exhibition_bookings(visitor_email);
CREATE INDEX idx_exhibition_bookings_date ON exhibition_bookings(preferred_date);
CREATE INDEX idx_exhibition_bookings_status ON exhibition_bookings(status);

CREATE TRIGGER update_exhibition_bookings_updated_date
    BEFORE UPDATE ON exhibition_bookings
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_date_column();

-- 13. EVENTS
CREATE TABLE events (
    id VARCHAR PRIMARY KEY,
    title VARCHAR NOT NULL,
    type VARCHAR NOT NULL,
    description TEXT,
    date DATE NOT NULL,
    start_time VARCHAR NOT NULL,
    end_time VARCHAR,
    location VARCHAR,
    image_url VARCHAR,
    media_gallery JSONB,
    featured_artists TEXT[],
    capacity INTEGER,
    tickets_sold INTEGER DEFAULT 0,
    ticket_price DECIMAL(10,2) DEFAULT 0,
    is_free BOOLEAN DEFAULT true,
    status VARCHAR DEFAULT 'upcoming',
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR
);

CREATE INDEX idx_events_date ON events(date);
CREATE INDEX idx_events_status ON events(status);
CREATE INDEX idx_events_type ON events(type);
CREATE INDEX idx_events_created_date ON events(created_date DESC);

CREATE TRIGGER update_events_updated_date
    BEFORE UPDATE ON events
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_date_column();

-- 14. EVENT BOOKINGS
CREATE TABLE event_bookings (
    id VARCHAR PRIMARY KEY,
    event_id VARCHAR NOT NULL,
    attendee_name VARCHAR NOT NULL,
    attendee_email VARCHAR NOT NULL,
    attendee_phone VARCHAR,
    number_of_tickets INTEGER DEFAULT 1,
    total_price DECIMAL(10,2) DEFAULT 0,
    ticket_code VARCHAR,
    payment_status VARCHAR DEFAULT 'pending',
    status VARCHAR DEFAULT 'confirmed',
    notes TEXT,
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR
);

CREATE INDEX idx_event_bookings_event ON event_bookings(event_id);
CREATE INDEX idx_event_bookings_email ON event_bookings(attendee_email);
CREATE INDEX idx_event_bookings_status ON event_bookings(status);
CREATE INDEX idx_event_bookings_ticket_code ON event_bookings(ticket_code);

CREATE TRIGGER update_event_bookings_updated_date
    BEFORE UPDATE ON event_bookings
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_date_column();

CREATE TRIGGER sync_event_tickets_insert
    AFTER INSERT ON event_bookings
    FOR EACH ROW
    EXECUTE FUNCTION sync_event_tickets_sold();

CREATE TRIGGER sync_event_tickets_delete
    AFTER DELETE ON event_bookings
    FOR EACH ROW
    EXECUTE FUNCTION sync_event_tickets_sold();

-- 15. EVENT TICKETS
CREATE TABLE event_tickets (
    id VARCHAR PRIMARY KEY,
    event_id VARCHAR NOT NULL,
    name VARCHAR NOT NULL,
    description TEXT,
    price DECIMAL(10,2) NOT NULL,
    quantity_available INTEGER NOT NULL,
    quantity_sold INTEGER DEFAULT 0,
    is_available BOOLEAN DEFAULT true,
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR
);

CREATE INDEX idx_event_tickets_event ON event_tickets(event_id);
CREATE INDEX idx_event_tickets_available ON event_tickets(is_available);

CREATE TRIGGER update_event_tickets_updated_date
    BEFORE UPDATE ON event_tickets
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_date_column();

-- 16. TICKET PURCHASES
CREATE TABLE ticket_purchases (
    id VARCHAR PRIMARY KEY,
    event_id VARCHAR NOT NULL,
    ticket_type_id VARCHAR NOT NULL,
    purchaser_name VARCHAR NOT NULL,
    purchaser_email VARCHAR NOT NULL,
    quantity INTEGER DEFAULT 1,
    total_price DECIMAL(10,2) NOT NULL,
    payment_status VARCHAR DEFAULT 'pending',
    ticket_codes TEXT[],
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR
);

CREATE INDEX idx_ticket_purchases_event ON ticket_purchases(event_id);
CREATE INDEX idx_ticket_purchases_email ON ticket_purchases(purchaser_email);
CREATE INDEX idx_ticket_purchases_payment ON ticket_purchases(payment_status);

CREATE TRIGGER update_ticket_purchases_updated_date
    BEFORE UPDATE ON ticket_purchases
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_date_column();

-- 17. COLLABORATIVE PROJECTS
CREATE TABLE collaborative_projects (
    id VARCHAR PRIMARY KEY,
    title VARCHAR NOT NULL,
    description TEXT,
    canvas_data TEXT,
    thumbnail_url VARCHAR,
    owner_email VARCHAR NOT NULL,
    collaborators TEXT[],
    status VARCHAR DEFAULT 'draft',
    art_style VARCHAR,
    color_palette TEXT[],
    tags TEXT[],
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR
);

CREATE INDEX idx_collab_projects_owner ON collaborative_projects(owner_email);
CREATE INDEX idx_collab_projects_status ON collaborative_projects(status);
CREATE INDEX idx_collab_projects_created ON collaborative_projects(created_date DESC);

CREATE TRIGGER update_collab_projects_updated_date
    BEFORE UPDATE ON collaborative_projects
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_date_column();

-- 18. PROJECT VERSIONS
CREATE TABLE project_versions (
    id VARCHAR PRIMARY KEY,
    project_id VARCHAR NOT NULL,
    version_number INTEGER NOT NULL,
    canvas_data TEXT,
    thumbnail_url VARCHAR,
    author_email VARCHAR NOT NULL,
    commit_message TEXT,
    is_milestone BOOLEAN DEFAULT false,
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR
);

CREATE INDEX idx_project_versions_project ON project_versions(project_id);
CREATE INDEX idx_project_versions_version ON project_versions(version_number);
CREATE INDEX idx_project_versions_milestone ON project_versions(is_milestone);

CREATE TRIGGER update_project_versions_updated_date
    BEFORE UPDATE ON project_versions
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_date_column();

-- 19. PROJECT COMMENTS
CREATE TABLE project_comments (
    id VARCHAR PRIMARY KEY,
    project_id VARCHAR NOT NULL,
    author_email VARCHAR NOT NULL,
    author_name VARCHAR,
    content TEXT NOT NULL,
    position_x DECIMAL(5,2),
    position_y DECIMAL(5,2),
    is_resolved BOOLEAN DEFAULT false,
    parent_comment_id VARCHAR,
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR
);

CREATE INDEX idx_project_comments_project ON project_comments(project_id);
CREATE INDEX idx_project_comments_author ON project_comments(author_email);
CREATE INDEX idx_project_comments_resolved ON project_comments(is_resolved);

CREATE TRIGGER update_project_comments_updated_date
    BEFORE UPDATE ON project_comments
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_date_column();

-- 20. PROJECT INVITATIONS
CREATE TABLE project_invitations (
    id VARCHAR PRIMARY KEY,
    project_id VARCHAR NOT NULL,
    project_title VARCHAR,
    inviter_email VARCHAR NOT NULL,
    inviter_name VARCHAR,
    invitee_email VARCHAR NOT NULL,
    message TEXT,
    role VARCHAR DEFAULT 'editor',
    status VARCHAR DEFAULT 'pending',
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR
);

CREATE INDEX idx_project_invites_project ON project_invitations(project_id);
CREATE INDEX idx_project_invites_invitee ON project_invitations(invitee_email);
CREATE INDEX idx_project_invites_status ON project_invitations(status);

CREATE TRIGGER update_project_invites_updated_date
    BEFORE UPDATE ON project_invitations
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_date_column();

-- 21. WISHLIST
CREATE TABLE wishlist (
    id VARCHAR PRIMARY KEY,
    artwork_id VARCHAR,
    merchandise_id VARCHAR,
    item_type VARCHAR DEFAULT 'artwork',
    notes TEXT,
    notify_back_in_stock BOOLEAN DEFAULT true,
    notify_on_sale BOOLEAN DEFAULT true,
    price_when_added DECIMAL(10,2),
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR
);

CREATE INDEX idx_wishlist_created_by ON wishlist(created_by);
CREATE INDEX idx_wishlist_artwork ON wishlist(artwork_id);
CREATE INDEX idx_wishlist_merchandise ON wishlist(merchandise_id);

CREATE TRIGGER update_wishlist_updated_date
    BEFORE UPDATE ON wishlist
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_date_column();

-- 22. SAVED POSTCARDS
CREATE TABLE saved_postcards (
    id VARCHAR PRIMARY KEY,
    station_name VARCHAR NOT NULL,
    station_image VARCHAR,
    message TEXT NOT NULL,
    recipient_name VARCHAR,
    sender_name VARCHAR,
    style VARCHAR,
    font VARCHAR,
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR
);

CREATE INDEX idx_saved_postcards_created_by ON saved_postcards(created_by);

CREATE TRIGGER update_saved_postcards_updated_date
    BEFORE UPDATE ON saved_postcards
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_date_column();

-- 23. PORTRAIT COMMISSIONS
CREATE TABLE portrait_commissions (
    id VARCHAR PRIMARY KEY,
    reference_images TEXT[],
    reference_image VARCHAR,
    brief_title VARCHAR,
    brief_description TEXT,
    mood_keywords TEXT[],
    color_preferences VARCHAR,
    artist_id VARCHAR,
    artist_name VARCHAR,
    style VARCHAR NOT NULL,
    size VARCHAR NOT NULL,
    custom_size VARCHAR,
    special_requests TEXT,
    background_preference VARCHAR DEFAULT 'Plain',
    total_price DECIMAL(10,2),
    deposit_paid DECIMAL(10,2),
    deposit_paid_at VARCHAR,
    balance_due DECIMAL(10,2),
    balance_paid BOOLEAN DEFAULT false,
    milestones JSONB,
    contact_email VARCHAR NOT NULL,
    contact_phone VARCHAR,
    status VARCHAR DEFAULT 'draft',
    progress_percentage INTEGER DEFAULT 0,
    progress_stage VARCHAR DEFAULT 'Awaiting Start',
    progress_notes TEXT,
    progress_image VARCHAR,
    progress_history JSONB,
    estimated_completion VARCHAR,
    revision_count INTEGER DEFAULT 0,
    max_revisions INTEGER DEFAULT 2,
    email_notifications BOOLEAN DEFAULT true,
    sms_notifications BOOLEAN DEFAULT false,
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR
);

CREATE INDEX idx_portrait_commissions_artist ON portrait_commissions(artist_id);
CREATE INDEX idx_portrait_commissions_email ON portrait_commissions(contact_email);
CREATE INDEX idx_portrait_commissions_status ON portrait_commissions(status);
CREATE INDEX idx_portrait_commissions_created_by ON portrait_commissions(created_by);

CREATE TRIGGER update_portrait_commissions_updated_date
    BEFORE UPDATE ON portrait_commissions
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_date_column();

-- 24. ART ROVER ROUTES
CREATE TABLE art_rover_routes (
    id VARCHAR PRIMARY KEY,
    name VARCHAR NOT NULL,
    description TEXT,
    states_covered TEXT[],
    assigned_rover VARCHAR,
    recurrence_pattern VARCHAR,
    is_active BOOLEAN DEFAULT true,
    next_run_date DATE,
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR
);

CREATE INDEX idx_rover_routes_active ON art_rover_routes(is_active);
CREATE INDEX idx_rover_routes_next_run ON art_rover_routes(next_run_date);

CREATE TRIGGER update_rover_routes_updated_date
    BEFORE UPDATE ON art_rover_routes
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_date_column();

-- 25. ART ROVER TOURS
CREATE TABLE art_rover_tours (
    id VARCHAR PRIMARY KEY,
    title VARCHAR NOT NULL,
    description TEXT,
    state VARCHAR NOT NULL,
    location_name VARCHAR NOT NULL,
    address VARCHAR,
    latitude DECIMAL(10,6),
    longitude DECIMAL(10,6),
    date DATE NOT NULL,
    start_time VARCHAR NOT NULL,
    end_time VARCHAR,
    event_type VARCHAR NOT NULL,
    slots_available INTEGER,
    slots_booked INTEGER DEFAULT 0,
    rover_unit VARCHAR,
    status VARCHAR DEFAULT 'upcoming',
    is_recurring BOOLEAN DEFAULT false,
    route_id VARCHAR,
    contact_email VARCHAR,
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR
);

CREATE INDEX idx_rover_tours_date ON art_rover_tours(date);
CREATE INDEX idx_rover_tours_state ON art_rover_tours(state);
CREATE INDEX idx_rover_tours_status ON art_rover_tours(status);
CREATE INDEX idx_rover_tours_route ON art_rover_tours(route_id);

CREATE TRIGGER update_rover_tours_updated_date
    BEFORE UPDATE ON art_rover_tours
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_date_column();

-- 26. ART ROVER BOOKINGS
CREATE TABLE art_rover_bookings (
    id VARCHAR PRIMARY KEY,
    tour_id VARCHAR NOT NULL,
    tour_title VARCHAR,
    booking_type VARCHAR NOT NULL,
    visitor_name VARCHAR NOT NULL,
    visitor_email VARCHAR NOT NULL,
    visitor_phone VARCHAR,
    party_size INTEGER DEFAULT 1,
    special_requests TEXT,
    status VARCHAR DEFAULT 'confirmed',
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR
);

CREATE INDEX idx_rover_bookings_tour ON art_rover_bookings(tour_id);
CREATE INDEX idx_rover_bookings_email ON art_rover_bookings(visitor_email);
CREATE INDEX idx_rover_bookings_status ON art_rover_bookings(status);

CREATE TRIGGER update_rover_bookings_updated_date
    BEFORE UPDATE ON art_rover_bookings
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_date_column();

-- 27. ART ROVER MEDIA
CREATE TABLE art_rover_media (
    id VARCHAR PRIMARY KEY,
    tour_id VARCHAR NOT NULL,
    media_type VARCHAR NOT NULL,
    url VARCHAR NOT NULL,
    caption TEXT,
    display_order INTEGER DEFAULT 0,
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR
);

CREATE INDEX idx_rover_media_tour ON art_rover_media(tour_id);
CREATE INDEX idx_rover_media_order ON art_rover_media(display_order);

CREATE TRIGGER update_rover_media_updated_date
    BEFORE UPDATE ON art_rover_media
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_date_column();

-- 28. MERCHANDISE
CREATE TABLE merchandise (
    id VARCHAR PRIMARY KEY,
    name VARCHAR NOT NULL,
    description TEXT,
    category VARCHAR NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    image_url VARCHAR,
    images TEXT[],
    sizes TEXT[],
    colors TEXT[],
    stock_quantity INTEGER DEFAULT 0,
    is_available BOOLEAN DEFAULT true,
    featured BOOLEAN DEFAULT false,
    artist_name VARCHAR,
    artwork_title VARCHAR,
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR
);

CREATE INDEX idx_merchandise_category ON merchandise(category);
CREATE INDEX idx_merchandise_available ON merchandise(is_available);
CREATE INDEX idx_merchandise_featured ON merchandise(featured);
CREATE INDEX idx_merchandise_price ON merchandise(price);

CREATE TRIGGER update_merchandise_updated_date
    BEFORE UPDATE ON merchandise
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_date_column();

-- 29. MERCH ORDERS
CREATE TABLE merch_orders (
    id VARCHAR PRIMARY KEY,
    items JSONB NOT NULL,
    total_price DECIMAL(10,2) NOT NULL,
    shipping_name VARCHAR NOT NULL,
    shipping_address VARCHAR NOT NULL,
    shipping_city VARCHAR,
    shipping_state VARCHAR,
    shipping_postcode VARCHAR,
    shipping_country VARCHAR,
    shipping_method VARCHAR DEFAULT 'standard',
    shipping_cost DECIMAL(10,2),
    payment_status VARCHAR DEFAULT 'pending',
    status VARCHAR DEFAULT 'pending',
    tracking_number VARCHAR,
    notes TEXT,
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR
);

CREATE INDEX idx_merch_orders_status ON merch_orders(status);
CREATE INDEX idx_merch_orders_payment ON merch_orders(payment_status);
CREATE INDEX idx_merch_orders_created_by ON merch_orders(created_by);
CREATE INDEX idx_merch_orders_created_date ON merch_orders(created_date DESC);

CREATE TRIGGER update_merch_orders_updated_date
    BEFORE UPDATE ON merch_orders
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_date_column();

-- 30. MERCH REVIEWS
CREATE TABLE merch_reviews (
    id VARCHAR PRIMARY KEY,
    merchandise_id VARCHAR NOT NULL,
    reviewer_name VARCHAR NOT NULL,
    reviewer_email VARCHAR NOT NULL,
    rating INTEGER NOT NULL,
    review_text TEXT,
    verified_purchase BOOLEAN DEFAULT false,
    status VARCHAR DEFAULT 'pending',
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR
);

CREATE INDEX idx_merch_reviews_merchandise ON merch_reviews(merchandise_id);
CREATE INDEX idx_merch_reviews_rating ON merch_reviews(rating);
CREATE INDEX idx_merch_reviews_status ON merch_reviews(status);

CREATE TRIGGER update_merch_reviews_updated_date
    BEFORE UPDATE ON merch_reviews
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_date_column();

-- 31. PROMO CODES
CREATE TABLE promo_codes (
    id VARCHAR PRIMARY KEY,
    code VARCHAR UNIQUE NOT NULL,
    description TEXT,
    discount_type VARCHAR NOT NULL,
    discount_value DECIMAL(10,2) NOT NULL,
    min_purchase_amount DECIMAL(10,2),
    max_discount_amount DECIMAL(10,2),
    valid_from DATE,
    valid_until DATE,
    usage_limit INTEGER,
    times_used INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    applicable_to TEXT[],
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR
);

CREATE INDEX idx_promo_codes_code ON promo_codes(code);
CREATE INDEX idx_promo_codes_active ON promo_codes(is_active);
CREATE INDEX idx_promo_codes_valid_until ON promo_codes(valid_until);

CREATE TRIGGER update_promo_codes_updated_date
    BEFORE UPDATE ON promo_codes
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_date_column();

-- 32. SAVED ADDRESSES
CREATE TABLE saved_addresses (
    id VARCHAR PRIMARY KEY,
    address_name VARCHAR,
    recipient_name VARCHAR NOT NULL,
    address_line1 VARCHAR NOT NULL,
    address_line2 VARCHAR,
    city VARCHAR NOT NULL,
    state VARCHAR NOT NULL,
    postcode VARCHAR NOT NULL,
    country VARCHAR DEFAULT 'Australia',
    phone VARCHAR,
    is_default BOOLEAN DEFAULT false,
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR
);

CREATE INDEX idx_saved_addresses_created_by ON saved_addresses(created_by);
CREATE INDEX idx_saved_addresses_default ON saved_addresses(is_default);

CREATE TRIGGER update_saved_addresses_updated_date
    BEFORE UPDATE ON saved_addresses
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_date_column();

-- 33. WORKSHOPS
CREATE TABLE workshops (
    id VARCHAR PRIMARY KEY,
    title VARCHAR NOT NULL,
    description TEXT,
    instructor VARCHAR NOT NULL,
    category VARCHAR NOT NULL,
    difficulty VARCHAR DEFAULT 'beginner',
    duration_hours DECIMAL(4,2) NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    image_url VARCHAR,
    materials_included TEXT[],
    what_to_bring TEXT[],
    max_participants INTEGER NOT NULL,
    min_participants INTEGER DEFAULT 1,
    is_recurring BOOLEAN DEFAULT false,
    recurrence_pattern VARCHAR,
    status VARCHAR DEFAULT 'active',
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR
);

CREATE INDEX idx_workshops_category ON workshops(category);
CREATE INDEX idx_workshops_status ON workshops(status);
CREATE INDEX idx_workshops_difficulty ON workshops(difficulty);

CREATE TRIGGER update_workshops_updated_date
    BEFORE UPDATE ON workshops
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_date_column();

-- 34. WORKSHOP SESSIONS
CREATE TABLE workshop_sessions (
    id VARCHAR PRIMARY KEY,
    workshop_id VARCHAR NOT NULL,
    date DATE NOT NULL,
    start_time VARCHAR NOT NULL,
    end_time VARCHAR NOT NULL,
    available_slots INTEGER NOT NULL,
    booked_slots INTEGER DEFAULT 0,
    status VARCHAR DEFAULT 'upcoming',
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR
);

CREATE INDEX idx_workshop_sessions_workshop ON workshop_sessions(workshop_id);
CREATE INDEX idx_workshop_sessions_date ON workshop_sessions(date);
CREATE INDEX idx_workshop_sessions_status ON workshop_sessions(status);

CREATE TRIGGER update_workshop_sessions_updated_date
    BEFORE UPDATE ON workshop_sessions
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_date_column();

-- 35. WORKSHOP BOOKINGS
CREATE TABLE workshop_bookings (
    id VARCHAR PRIMARY KEY,
    workshop_id VARCHAR NOT NULL,
    session_id VARCHAR NOT NULL,
    participant_name VARCHAR NOT NULL,
    participant_email VARCHAR NOT NULL,
    participant_phone VARCHAR,
    number_of_tickets INTEGER DEFAULT 1,
    total_price DECIMAL(10,2) NOT NULL,
    payment_status VARCHAR DEFAULT 'pending',
    status VARCHAR DEFAULT 'confirmed',
    special_requests TEXT,
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR
);

CREATE INDEX idx_workshop_bookings_workshop ON workshop_bookings(workshop_id);
CREATE INDEX idx_workshop_bookings_session ON workshop_bookings(session_id);
CREATE INDEX idx_workshop_bookings_email ON workshop_bookings(participant_email);
CREATE INDEX idx_workshop_bookings_status ON workshop_bookings(status);

CREATE TRIGGER update_workshop_bookings_updated_date
    BEFORE UPDATE ON workshop_bookings
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_date_column();

CREATE TRIGGER sync_workshop_slots_insert
    AFTER INSERT ON workshop_bookings
    FOR EACH ROW
    EXECUTE FUNCTION sync_workshop_booked_slots();

CREATE TRIGGER sync_workshop_slots_delete
    AFTER DELETE ON workshop_bookings
    FOR EACH ROW
    EXECUTE FUNCTION sync_workshop_booked_slots();

-- 36. WORKSHOP WAITLIST
CREATE TABLE workshop_waitlist (
    id VARCHAR PRIMARY KEY,
    workshop_id VARCHAR NOT NULL,
    session_id VARCHAR NOT NULL,
    participant_name VARCHAR NOT NULL,
    participant_email VARCHAR NOT NULL,
    participant_phone VARCHAR,
    requested_tickets INTEGER DEFAULT 1,
    status VARCHAR DEFAULT 'waiting',
    notified_date VARCHAR,
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR
);

CREATE INDEX idx_workshop_waitlist_workshop ON workshop_waitlist(workshop_id);
CREATE INDEX idx_workshop_waitlist_session ON workshop_waitlist(session_id);
CREATE INDEX idx_workshop_waitlist_email ON workshop_waitlist(participant_email);
CREATE INDEX idx_workshop_waitlist_status ON workshop_waitlist(status);

CREATE TRIGGER update_workshop_waitlist_updated_date
    BEFORE UPDATE ON workshop_waitlist
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_date_column();

-- 37. AUCTIONS
CREATE TABLE auctions (
    id VARCHAR PRIMARY KEY,
    artwork_id VARCHAR NOT NULL,
    title VARCHAR NOT NULL,
    description TEXT,
    starting_bid DECIMAL(10,2) NOT NULL,
    current_bid DECIMAL(10,2),
    bid_increment DECIMAL(10,2) DEFAULT 50,
    reserve_price DECIMAL(10,2),
    buy_now_price DECIMAL(10,2),
    start_time TIMESTAMP NOT NULL,
    end_time TIMESTAMP NOT NULL,
    status VARCHAR DEFAULT 'upcoming',
    winner_id VARCHAR,
    total_bids INTEGER DEFAULT 0,
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR
);

CREATE INDEX idx_auctions_artwork ON auctions(artwork_id);
CREATE INDEX idx_auctions_status ON auctions(status);
CREATE INDEX idx_auctions_start_time ON auctions(start_time);
CREATE INDEX idx_auctions_end_time ON auctions(end_time);
CREATE INDEX idx_auctions_current_bid ON auctions(current_bid DESC);

CREATE TRIGGER update_auctions_updated_date
    BEFORE UPDATE ON auctions
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_date_column();

-- 38. AUCTION BIDS
CREATE TABLE auction_bids (
    id VARCHAR PRIMARY KEY,
    auction_id VARCHAR NOT NULL,
    bidder_email VARCHAR NOT NULL,
    bid_amount DECIMAL(10,2) NOT NULL,
    is_autobid BOOLEAN DEFAULT false,
    max_autobid_amount DECIMAL(10,2),
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR
);

CREATE INDEX idx_auction_bids_auction ON auction_bids(auction_id);
CREATE INDEX idx_auction_bids_bidder ON auction_bids(bidder_email);
CREATE INDEX idx_auction_bids_amount ON auction_bids(bid_amount DESC);
CREATE INDEX idx_auction_bids_created ON auction_bids(created_date DESC);

CREATE TRIGGER update_auction_bids_updated_date
    BEFORE UPDATE ON auction_bids
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_date_column();

CREATE TRIGGER sync_auction_bids_insert
    AFTER INSERT ON auction_bids
    FOR EACH ROW
    EXECUTE FUNCTION sync_auction_bid_count();

-- 39. AUCTION WATCHLIST
CREATE TABLE auction_watchlist (
    id VARCHAR PRIMARY KEY,
    auction_id VARCHAR NOT NULL,
    watcher_email VARCHAR NOT NULL,
    notify_on_bid BOOLEAN DEFAULT true,
    notify_before_end BOOLEAN DEFAULT true,
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR,
    UNIQUE(auction_id, watcher_email)
);

CREATE INDEX idx_auction_watchlist_auction ON auction_watchlist(auction_id);
CREATE INDEX idx_auction_watchlist_watcher ON auction_watchlist(watcher_email);

CREATE TRIGGER update_auction_watchlist_updated_date
    BEFORE UPDATE ON auction_watchlist
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_date_column();

-- 40. AUCTION WINNERS
CREATE TABLE auction_winners (
    id VARCHAR PRIMARY KEY,
    auction_id VARCHAR NOT NULL,
    winner_email VARCHAR NOT NULL,
    winning_bid DECIMAL(10,2) NOT NULL,
    payment_status VARCHAR DEFAULT 'pending',
    payment_date VARCHAR,
    shipping_status VARCHAR DEFAULT 'pending',
    shipping_date VARCHAR,
    tracking_number VARCHAR,
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR
);

CREATE INDEX idx_auction_winners_auction ON auction_winners(auction_id);
CREATE INDEX idx_auction_winners_email ON auction_winners(winner_email);
CREATE INDEX idx_auction_winners_payment ON auction_winners(payment_status);
CREATE INDEX idx_auction_winners_shipping ON auction_winners(shipping_status);

CREATE TRIGGER update_auction_winners_updated_date
    BEFORE UPDATE ON auction_winners
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_date_column();

-- 41. NOTIFICATIONS
CREATE TABLE notifications (
    id VARCHAR PRIMARY KEY,
    user_email VARCHAR NOT NULL,
    type VARCHAR NOT NULL,
    title VARCHAR NOT NULL,
    message TEXT NOT NULL,
    link VARCHAR,
    is_read BOOLEAN DEFAULT false,
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR
);

CREATE INDEX idx_notifications_user ON notifications(user_email);
CREATE INDEX idx_notifications_read ON notifications(is_read);
CREATE INDEX idx_notifications_type ON notifications(type);
CREATE INDEX idx_notifications_created ON notifications(created_date DESC);

CREATE TRIGGER update_notifications_updated_date
    BEFORE UPDATE ON notifications
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_date_column();

-- 42. NOTIFICATION PREFERENCES
CREATE TABLE notification_preferences (
    id VARCHAR PRIMARY KEY,
    user_email VARCHAR NOT NULL UNIQUE,
    email_notifications BOOLEAN DEFAULT true,
    sms_notifications BOOLEAN DEFAULT false,
    auction_updates BOOLEAN DEFAULT true,
    event_reminders BOOLEAN DEFAULT true,
    new_artwork_alerts BOOLEAN DEFAULT true,
    artist_updates BOOLEAN DEFAULT true,
    newsletter BOOLEAN DEFAULT true,
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR
);

CREATE INDEX idx_notification_prefs_user ON notification_preferences(user_email);

CREATE TRIGGER update_notification_prefs_updated_date
    BEFORE UPDATE ON notification_preferences
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_date_column();

-- 43. DISCUSSIONS
CREATE TABLE discussions (
    id VARCHAR PRIMARY KEY,
    title VARCHAR NOT NULL,
    content TEXT NOT NULL,
    author_email VARCHAR NOT NULL,
    author_name VARCHAR,
    category VARCHAR,
    tags TEXT[],
    likes_count INTEGER DEFAULT 0,
    comments_count INTEGER DEFAULT 0,
    is_pinned BOOLEAN DEFAULT false,
    status VARCHAR DEFAULT 'active',
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR
);

CREATE INDEX idx_discussions_author ON discussions(author_email);
CREATE INDEX idx_discussions_category ON discussions(category);
CREATE INDEX idx_discussions_status ON discussions(status);
CREATE INDEX idx_discussions_created ON discussions(created_date DESC);
CREATE INDEX idx_discussions_pinned ON discussions(is_pinned);

CREATE TRIGGER update_discussions_updated_date
    BEFORE UPDATE ON discussions
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_date_column();

-- 44. DISCUSSION COMMENTS
CREATE TABLE discussion_comments (
    id VARCHAR PRIMARY KEY,
    discussion_id VARCHAR NOT NULL,
    author_email VARCHAR NOT NULL,
    author_name VARCHAR,
    content TEXT NOT NULL,
    parent_comment_id VARCHAR,
    likes_count INTEGER DEFAULT 0,
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR
);

CREATE INDEX idx_discussion_comments_discussion ON discussion_comments(discussion_id);
CREATE INDEX idx_discussion_comments_author ON discussion_comments(author_email);
CREATE INDEX idx_discussion_comments_parent ON discussion_comments(parent_comment_id);
CREATE INDEX idx_discussion_comments_created ON discussion_comments(created_date DESC);

CREATE TRIGGER update_discussion_comments_updated_date
    BEFORE UPDATE ON discussion_comments
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_date_column();

-- 45. GENERATED ART
CREATE TABLE generated_art (
    id VARCHAR PRIMARY KEY,
    prompt TEXT NOT NULL,
    style VARCHAR,
    image_url VARCHAR NOT NULL,
    thumbnail_url VARCHAR,
    creator_email VARCHAR NOT NULL,
    is_public BOOLEAN DEFAULT true,
    likes_count INTEGER DEFAULT 0,
    generation_params JSONB,
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR
);

CREATE INDEX idx_generated_art_creator ON generated_art(creator_email);
CREATE INDEX idx_generated_art_public ON generated_art(is_public);
CREATE INDEX idx_generated_art_style ON generated_art(style);
CREATE INDEX idx_generated_art_created ON generated_art(created_date DESC);

CREATE TRIGGER update_generated_art_updated_date
    BEFORE UPDATE ON generated_art
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_date_column();

-- 46. AI ART LISTINGS
CREATE TABLE ai_art_listings (
    id VARCHAR PRIMARY KEY,
    generated_art_id VARCHAR NOT NULL,
    title VARCHAR NOT NULL,
    description TEXT,
    price DECIMAL(10,2) NOT NULL,
    seller_email VARCHAR NOT NULL,
    is_available BOOLEAN DEFAULT true,
    sales_count INTEGER DEFAULT 0,
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR
);

CREATE INDEX idx_ai_art_listings_art ON ai_art_listings(generated_art_id);
CREATE INDEX idx_ai_art_listings_seller ON ai_art_listings(seller_email);
CREATE INDEX idx_ai_art_listings_available ON ai_art_listings(is_available);
CREATE INDEX idx_ai_art_listings_price ON ai_art_listings(price);

CREATE TRIGGER update_ai_art_listings_updated_date
    BEFORE UPDATE ON ai_art_listings
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_date_column();

-- 47. AI ART PURCHASES
CREATE TABLE ai_art_purchases (
    id VARCHAR PRIMARY KEY,
    listing_id VARCHAR NOT NULL,
    generated_art_id VARCHAR NOT NULL,
    buyer_email VARCHAR NOT NULL,
    price_paid DECIMAL(10,2) NOT NULL,
    payment_status VARCHAR DEFAULT 'pending',
    download_url VARCHAR,
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR
);

CREATE INDEX idx_ai_art_purchases_listing ON ai_art_purchases(listing_id);
CREATE INDEX idx_ai_art_purchases_buyer ON ai_art_purchases(buyer_email);
CREATE INDEX idx_ai_art_purchases_payment ON ai_art_purchases(payment_status);

CREATE TRIGGER update_ai_art_purchases_updated_date
    BEFORE UPDATE ON ai_art_purchases
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_date_column();

-- 48. PREMIUM SUBSCRIPTIONS
CREATE TABLE premium_subscriptions (
    id VARCHAR PRIMARY KEY,
    user_email VARCHAR NOT NULL,
    plan_type VARCHAR NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    status VARCHAR DEFAULT 'active',
    generations_used INTEGER DEFAULT 0,
    generations_limit INTEGER NOT NULL,
    price_paid DECIMAL(10,2) NOT NULL,
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR
);

CREATE INDEX idx_premium_subs_user ON premium_subscriptions(user_email);
CREATE INDEX idx_premium_subs_status ON premium_subscriptions(status);
CREATE INDEX idx_premium_subs_end_date ON premium_subscriptions(end_date);

CREATE TRIGGER update_premium_subs_updated_date
    BEFORE UPDATE ON premium_subscriptions
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_date_column();

-- 49. ARTIST ROYALTIES
CREATE TABLE artist_royalties (
    id VARCHAR PRIMARY KEY,
    artist_email VARCHAR NOT NULL,
    sale_id VARCHAR NOT NULL,
    sale_type VARCHAR NOT NULL,
    sale_amount DECIMAL(10,2) NOT NULL,
    royalty_percentage DECIMAL(5,2) NOT NULL,
    royalty_amount DECIMAL(10,2) NOT NULL,
    status VARCHAR DEFAULT 'pending',
    paid_date VARCHAR,
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR
);

CREATE INDEX idx_artist_royalties_artist ON artist_royalties(artist_email);
CREATE INDEX idx_artist_royalties_status ON artist_royalties(status);
CREATE INDEX idx_artist_royalties_sale ON artist_royalties(sale_id);

CREATE TRIGGER update_artist_royalties_updated_date
    BEFORE UPDATE ON artist_royalties
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_date_column();

-- 50. COLLECTIONS
CREATE TABLE collections (
    id VARCHAR PRIMARY KEY,
    name VARCHAR NOT NULL,
    description TEXT,
    cover_image VARCHAR,
    creator_email VARCHAR NOT NULL,
    is_public BOOLEAN DEFAULT true,
    artwork_ids TEXT[],
    likes_count INTEGER DEFAULT 0,
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR
);

CREATE INDEX idx_collections_creator ON collections(creator_email);
CREATE INDEX idx_collections_public ON collections(is_public);
CREATE INDEX idx_collections_likes ON collections(likes_count DESC);

CREATE TRIGGER update_collections_updated_date
    BEFORE UPDATE ON collections
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_date_column();

-- 51. COLLECTION LIKES
CREATE TABLE collection_likes (
    id VARCHAR PRIMARY KEY,
    collection_id VARCHAR NOT NULL,
    liker_email VARCHAR NOT NULL,
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR,
    UNIQUE(collection_id, liker_email)
);

CREATE INDEX idx_collection_likes_collection ON collection_likes(collection_id);
CREATE INDEX idx_collection_likes_liker ON collection_likes(liker_email);

CREATE TRIGGER update_collection_likes_updated_date
    BEFORE UPDATE ON collection_likes
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_date_column();

CREATE TRIGGER sync_collection_likes_insert
    AFTER INSERT ON collection_likes
    FOR EACH ROW
    EXECUTE FUNCTION sync_collection_likes_count();

CREATE TRIGGER sync_collection_likes_delete
    AFTER DELETE ON collection_likes
    FOR EACH ROW
    EXECUTE FUNCTION sync_collection_likes_count();

-- 52. ARTWORK VOTES
CREATE TABLE artwork_votes (
    id VARCHAR PRIMARY KEY,
    artwork_id VARCHAR NOT NULL,
    voter_email VARCHAR NOT NULL,
    vote_type VARCHAR NOT NULL,
    category VARCHAR,
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR,
    UNIQUE(artwork_id, voter_email, category)
);

CREATE INDEX idx_artwork_votes_artwork ON artwork_votes(artwork_id);
CREATE INDEX idx_artwork_votes_voter ON artwork_votes(voter_email);
CREATE INDEX idx_artwork_votes_category ON artwork_votes(category);

CREATE TRIGGER update_artwork_votes_updated_date
    BEFORE UPDATE ON artwork_votes
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_date_column();

-- 53. USER GALLERIES
CREATE TABLE user_galleries (
    id VARCHAR PRIMARY KEY,
    name VARCHAR NOT NULL,
    description TEXT,
    cover_image VARCHAR,
    owner_email VARCHAR NOT NULL,
    is_public BOOLEAN DEFAULT true,
    layout_type VARCHAR DEFAULT 'grid',
    artwork_ids TEXT[],
    views_count INTEGER DEFAULT 0,
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR
);

CREATE INDEX idx_user_galleries_owner ON user_galleries(owner_email);
CREATE INDEX idx_user_galleries_public ON user_galleries(is_public);
CREATE INDEX idx_user_galleries_views ON user_galleries(views_count DESC);

CREATE TRIGGER update_user_galleries_updated_date
    BEFORE UPDATE ON user_galleries
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_date_column();

-- 54. ARTIST REQUESTS
CREATE TABLE artist_requests (
    id VARCHAR PRIMARY KEY,
    requester_name VARCHAR NOT NULL,
    requester_email VARCHAR NOT NULL,
    artist_name VARCHAR NOT NULL,
    portfolio_url VARCHAR,
    social_media TEXT[],
    bio TEXT,
    specialties TEXT[],
    reason TEXT,
    status VARCHAR DEFAULT 'pending',
    reviewed_by VARCHAR,
    reviewed_date VARCHAR,
    notes TEXT,
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR
);

CREATE INDEX idx_artist_requests_status ON artist_requests(status);
CREATE INDEX idx_artist_requests_requester ON artist_requests(requester_email);
CREATE INDEX idx_artist_requests_created ON artist_requests(created_date DESC);

CREATE TRIGGER update_artist_requests_updated_date
    BEFORE UPDATE ON artist_requests
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_date_column();

-- 55. CLASS 53 EVENTS
CREATE TABLE class53_events (
    id VARCHAR PRIMARY KEY,
    title VARCHAR NOT NULL,
    description TEXT,
    event_type VARCHAR NOT NULL,
    date DATE NOT NULL,
    start_time VARCHAR NOT NULL,
    end_time VARCHAR,
    location VARCHAR,
    capacity INTEGER,
    tickets_sold INTEGER DEFAULT 0,
    ticket_price DECIMAL(10,2) NOT NULL,
    image_url VARCHAR,
    status VARCHAR DEFAULT 'upcoming',
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR
);

CREATE INDEX idx_class53_events_date ON class53_events(date);
CREATE INDEX idx_class53_events_type ON class53_events(event_type);
CREATE INDEX idx_class53_events_status ON class53_events(status);

CREATE TRIGGER update_class53_events_updated_date
    BEFORE UPDATE ON class53_events
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_date_column();

-- 56. CLASS 53 BOOKINGS
CREATE TABLE class53_bookings (
    id VARCHAR PRIMARY KEY,
    event_id VARCHAR NOT NULL,
    attendee_name VARCHAR NOT NULL,
    attendee_email VARCHAR NOT NULL,
    attendee_phone VARCHAR,
    number_of_tickets INTEGER DEFAULT 1,
    total_price DECIMAL(10,2) NOT NULL,
    payment_status VARCHAR DEFAULT 'pending',
    status VARCHAR DEFAULT 'confirmed',
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR
);

CREATE INDEX idx_class53_bookings_event ON class53_bookings(event_id);
CREATE INDEX idx_class53_bookings_email ON class53_bookings(attendee_email);
CREATE INDEX idx_class53_bookings_status ON class53_bookings(status);

CREATE TRIGGER update_class53_bookings_updated_date
    BEFORE UPDATE ON class53_bookings
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_date_column();

-- 57. CLASS 53 AFFILIATES
CREATE TABLE class53_affiliates (
    id VARCHAR PRIMARY KEY,
    name VARCHAR NOT NULL,
    email VARCHAR NOT NULL,
    phone VARCHAR,
    organization VARCHAR,
    referral_code VARCHAR UNIQUE NOT NULL,
    commission_rate DECIMAL(5,2) DEFAULT 10.00,
    total_referrals INTEGER DEFAULT 0,
    total_earned DECIMAL(10,2) DEFAULT 0,
    status VARCHAR DEFAULT 'active',
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR
);

CREATE INDEX idx_class53_affiliates_code ON class53_affiliates(referral_code);
CREATE INDEX idx_class53_affiliates_email ON class53_affiliates(email);
CREATE INDEX idx_class53_affiliates_status ON class53_affiliates(status);

CREATE TRIGGER update_class53_affiliates_updated_date
    BEFORE UPDATE ON class53_affiliates
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_date_column();

-- 58. CLASS 53 NEWSLETTER
CREATE TABLE class53_newsletter (
    id VARCHAR PRIMARY KEY,
    email VARCHAR UNIQUE NOT NULL,
    name VARCHAR,
    subscribed_date DATE NOT NULL,
    is_active BOOLEAN DEFAULT true,
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR
);

CREATE INDEX idx_class53_newsletter_email ON class53_newsletter(email);
CREATE INDEX idx_class53_newsletter_active ON class53_newsletter(is_active);

CREATE TRIGGER update_class53_newsletter_updated_date
    BEFORE UPDATE ON class53_newsletter
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_date_column();

-- 59. AFFILIATE MEDIA
CREATE TABLE affiliate_media (
    id VARCHAR PRIMARY KEY,
    affiliate_id VARCHAR NOT NULL,
    media_type VARCHAR NOT NULL,
    url VARCHAR NOT NULL,
    title VARCHAR,
    description TEXT,
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR
);

CREATE INDEX idx_affiliate_media_affiliate ON affiliate_media(affiliate_id);
CREATE INDEX idx_affiliate_media_type ON affiliate_media(media_type);

CREATE TRIGGER update_affiliate_media_updated_date
    BEFORE UPDATE ON affiliate_media
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_date_column();

-- 60. AFFILIATE REFERRALS
CREATE TABLE affiliate_referrals (
    id VARCHAR PRIMARY KEY,
    affiliate_id VARCHAR NOT NULL,
    referral_code VARCHAR NOT NULL,
    booking_id VARCHAR NOT NULL,
    booking_type VARCHAR NOT NULL,
    sale_amount DECIMAL(10,2) NOT NULL,
    commission_amount DECIMAL(10,2) NOT NULL,
    status VARCHAR DEFAULT 'pending',
    paid_date VARCHAR,
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR
);

CREATE INDEX idx_affiliate_referrals_affiliate ON affiliate_referrals(affiliate_id);
CREATE INDEX idx_affiliate_referrals_code ON affiliate_referrals(referral_code);
CREATE INDEX idx_affiliate_referrals_status ON affiliate_referrals(status);

CREATE TRIGGER update_affiliate_referrals_updated_date
    BEFORE UPDATE ON affiliate_referrals
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_date_column();

-- 61. AWARDS
CREATE TABLE awards (
    id VARCHAR PRIMARY KEY,
    name VARCHAR NOT NULL,
    description TEXT,
    year INTEGER NOT NULL,
    category VARCHAR NOT NULL,
    voting_start DATE NOT NULL,
    voting_end DATE NOT NULL,
    winner_id VARCHAR,
    total_votes INTEGER DEFAULT 0,
    status VARCHAR DEFAULT 'upcoming',
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR
);

CREATE INDEX idx_awards_year ON awards(year);
CREATE INDEX idx_awards_category ON awards(category);
CREATE INDEX idx_awards_status ON awards(status);

CREATE TRIGGER update_awards_updated_date
    BEFORE UPDATE ON awards
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_date_column();

-- 62. ARTIST SCORES
CREATE TABLE artist_scores (
    id VARCHAR PRIMARY KEY,
    artist_id VARCHAR NOT NULL,
    category VARCHAR NOT NULL,
    total_votes INTEGER DEFAULT 0,
    average_score DECIMAL(5,2) DEFAULT 0,
    year INTEGER NOT NULL,
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR,
    UNIQUE(artist_id, category, year)
);

CREATE INDEX idx_artist_scores_artist ON artist_scores(artist_id);
CREATE INDEX idx_artist_scores_category ON artist_scores(category);
CREATE INDEX idx_artist_scores_year ON artist_scores(year);
CREATE INDEX idx_artist_scores_average ON artist_scores(average_score DESC);

CREATE TRIGGER update_artist_scores_updated_date
    BEFORE UPDATE ON artist_scores
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_date_column();

-- 63. VOTE CATEGORIES
CREATE TABLE vote_categories (
    id VARCHAR PRIMARY KEY,
    name VARCHAR NOT NULL,
    description TEXT,
    icon VARCHAR,
    is_active BOOLEAN DEFAULT true,
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR
);

CREATE INDEX idx_vote_categories_active ON vote_categories(is_active);

CREATE TRIGGER update_vote_categories_updated_date
    BEFORE UPDATE ON vote_categories
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_date_column();

-- 64. VOTES
CREATE TABLE votes (
    id VARCHAR PRIMARY KEY,
    voter_email VARCHAR NOT NULL,
    artist_id VARCHAR NOT NULL,
    category_id VARCHAR NOT NULL,
    score INTEGER NOT NULL,
    year INTEGER NOT NULL,
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR,
    UNIQUE(voter_email, artist_id, category_id, year)
);

CREATE INDEX idx_votes_voter ON votes(voter_email);
CREATE INDEX idx_votes_artist ON votes(artist_id);
CREATE INDEX idx_votes_category ON votes(category_id);
CREATE INDEX idx_votes_year ON votes(year);

CREATE TRIGGER update_votes_updated_date
    BEFORE UPDATE ON votes
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_date_column();

-- 65. CRM CLIENTS
CREATE TABLE crm_clients (
    id VARCHAR PRIMARY KEY,
    name VARCHAR NOT NULL,
    email VARCHAR NOT NULL,
    phone VARCHAR,
    company VARCHAR,
    address TEXT,
    tags TEXT[],
    status VARCHAR DEFAULT 'active',
    lifetime_value DECIMAL(10,2) DEFAULT 0,
    last_contact_date DATE,
    notes TEXT,
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR
);

CREATE INDEX idx_crm_clients_email ON crm_clients(email);
CREATE INDEX idx_crm_clients_status ON crm_clients(status);
CREATE INDEX idx_crm_clients_value ON crm_clients(lifetime_value DESC);

CREATE TRIGGER update_crm_clients_updated_date
    BEFORE UPDATE ON crm_clients
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_date_column();

-- 66. CRM INTERACTIONS
CREATE TABLE crm_interactions (
    id VARCHAR PRIMARY KEY,
    client_id VARCHAR NOT NULL,
    interaction_type VARCHAR NOT NULL,
    subject VARCHAR,
    notes TEXT,
    interaction_date TIMESTAMP NOT NULL,
    staff_member VARCHAR,
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR
);

CREATE INDEX idx_crm_interactions_client ON crm_interactions(client_id);
CREATE INDEX idx_crm_interactions_type ON crm_interactions(interaction_type);
CREATE INDEX idx_crm_interactions_date ON crm_interactions(interaction_date DESC);

CREATE TRIGGER update_crm_interactions_updated_date
    BEFORE UPDATE ON crm_interactions
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_date_column();

-- 67. CRM CAMPAIGNS
CREATE TABLE crm_campaigns (
    id VARCHAR PRIMARY KEY,
    name VARCHAR NOT NULL,
    description TEXT,
    campaign_type VARCHAR NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE,
    target_segment VARCHAR,
    status VARCHAR DEFAULT 'draft',
    sent_count INTEGER DEFAULT 0,
    opened_count INTEGER DEFAULT 0,
    clicked_count INTEGER DEFAULT 0,
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR
);

CREATE INDEX idx_crm_campaigns_status ON crm_campaigns(status);
CREATE INDEX idx_crm_campaigns_type ON crm_campaigns(campaign_type);
CREATE INDEX idx_crm_campaigns_start ON crm_campaigns(start_date);

CREATE TRIGGER update_crm_campaigns_updated_date
    BEFORE UPDATE ON crm_campaigns
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_date_column();

-- 68. CRM SEGMENTS
CREATE TABLE crm_segments (
    id VARCHAR PRIMARY KEY,
    name VARCHAR NOT NULL,
    description TEXT,
    criteria JSONB NOT NULL,
    client_count INTEGER DEFAULT 0,
    is_dynamic BOOLEAN DEFAULT true,
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR
);

CREATE INDEX idx_crm_segments_dynamic ON crm_segments(is_dynamic);

CREATE TRIGGER update_crm_segments_updated_date
    BEFORE UPDATE ON crm_segments
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_date_column();

-- 69. CRM WORKFLOWS
CREATE TABLE crm_workflows (
    id VARCHAR PRIMARY KEY,
    name VARCHAR NOT NULL,
    description TEXT,
    trigger_type VARCHAR NOT NULL,
    trigger_conditions JSONB,
    actions JSONB NOT NULL,
    is_active BOOLEAN DEFAULT true,
    execution_count INTEGER DEFAULT 0,
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR
);

CREATE INDEX idx_crm_workflows_active ON crm_workflows(is_active);
CREATE INDEX idx_crm_workflows_trigger ON crm_workflows(trigger_type);

CREATE TRIGGER update_crm_workflows_updated_date
    BEFORE UPDATE ON crm_workflows
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_date_column();

-- 70. CRM TASKS
CREATE TABLE crm_tasks (
    id VARCHAR PRIMARY KEY,
    title VARCHAR NOT NULL,
    description TEXT,
    client_id VARCHAR,
    assigned_to VARCHAR NOT NULL,
    due_date DATE,
    priority VARCHAR DEFAULT 'medium',
    status VARCHAR DEFAULT 'pending',
    completed_date DATE,
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR
);

CREATE INDEX idx_crm_tasks_assigned ON crm_tasks(assigned_to);
CREATE INDEX idx_crm_tasks_client ON crm_tasks(client_id);
CREATE INDEX idx_crm_tasks_status ON crm_tasks(status);
CREATE INDEX idx_crm_tasks_due ON crm_tasks(due_date);
CREATE INDEX idx_crm_tasks_priority ON crm_tasks(priority);

CREATE TRIGGER update_crm_tasks_updated_date
    BEFORE UPDATE ON crm_tasks
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_date_column();



INSERT INTO artists (id, name, bio, profile_image, specialties, location, website, instagram, is_featured, is_available, commission_base_price, accepts_messages, accepts_donations, user_email, created_by) VALUES
(1,'Sarah Chen', 'Contemporary abstract artist specializing in large-scale installations and mixed media works. Sarah''s work explores the intersection of nature and urban life, creating pieces that invite viewers to reflect on their relationship with the environment.', 'https://images.unsplash.com/photo-1494790108377-be9c29b29330', '{"Abstract", "Mixed Media", "Installation", "Contemporary"}', 'Melbourne, VIC', 'https://sarahchen.art', '@sarahchen_art', true, true, 500.00, true, true, 'sarah.chen@example.com', 'admin@53coxroad.com'),
(2,'Marcus Rivera', 'Award-winning portrait artist with 15 years of experience in oil painting and charcoal sketches. Marcus brings a classical approach to contemporary portraiture, capturing not just likeness but the essence of his subjects.', 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d', '{"Portraits", "Oil Painting", "Charcoal", "Figurative"}', 'Sydney, NSW', 'https://marcusrivera.com.au', '@marcus_rivera_art', true, true, 800.00, true, false, 'marcus.rivera@example.com', 'admin@53coxroad.com'),
(3,'Emma Thompson', 'Landscape watercolorist inspired by Australian coastal scenery. Emma''s delicate brushwork and vibrant color palettes capture the ever-changing beauty of Australia''s shorelines.', 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80', '{"Watercolor", "Landscapes", "Coastal", "Plein Air"}', 'Brisbane, QLD', 'https://emmathompson.art', '@emma_paints', true, true, 350.00, true, true, 'emma.thompson@example.com', 'admin@53coxroad.com'),
(4,'David Kim', 'Sculptor working primarily with recycled metals and found objects, creating thought-provoking pieces about sustainability and consumption.', 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e', '{"Sculpture", "Installation", "Metal Work", "Environmental Art"}', 'Adelaide, SA', 'https://davidkim.studio', '@davidkim_sculptor', false, true, 1200.00, true, true, 'david.kim@example.com', 'admin@53coxroad.com'),
(5,'Isabella Martinez', 'Ceramic artist creating functional art pieces inspired by ancient pottery techniques and modern minimalist design.', 'https://images.unsplash.com/photo-1544005313-94ddf0286df2', '{"Ceramics", "Pottery", "Functional Art", "Minimalist"}', 'Perth, WA', 'https://isabellamartinez.com', '@bella_ceramics', false, true, 400.00, true, false, 'isabella.martinez@example.com', 'admin@53coxroad.com'),
(6,'James Wu', 'Digital artist and photographer exploring the boundaries between reality and digital manipulation through stunning photographic composites.', 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d', '{"Photography", "Digital Art", "Photo Manipulation", "Contemporary"}', 'Melbourne, VIC', 'https://jameswu.photo', '@james_wu_photo', true, true, 600.00, true, true, 'james.wu@example.com', 'admin@53coxroad.com');



INSERT INTO artworks (id, title, artist, description, price, image_url, garden_origin, art_style, dimensions, year_created, featured, nar_registry_number, is_in_stock, created_by) VALUES
(1,'Sunset Over The Bay', 'Emma Thompson', 'Vibrant watercolor capturing the golden hour at Byron Bay, where warm oranges and purples blend seamlessly across the canvas.', 450.00, 'https://images.unsplash.com/photo-1579783902614-a3fb3927b6a5', 'Rose Garden', 'Painting', '50cm x 70cm', 2024, true, 'NAR-2024-001', true, 'admin@53coxroad.com'),
(2,'Urban Reflection', 'Sarah Chen', 'Abstract mixed media exploring city life and human connection through layers of paint, fabric, and found urban materials.', 1200.00, 'https://images.unsplash.com/photo-1541961017774-22349e4a1262', 'Studio', 'Mixed Media', '120cm x 150cm', 2024, true, 'NAR-2024-002', true, 'admin@53coxroad.com'),
(3,'The Matriarch', 'Marcus Rivera', 'Powerful oil portrait of strength and resilience, capturing the wisdom and dignity of age through masterful brushwork.', 2500.00, 'https://images.unsplash.com/photo-1578301978018-3005759f48f7', 'Studio', 'Painting', '80cm x 100cm', 2023, true, 'NAR-2024-003', true, 'admin@53coxroad.com'),
(4,'Coastal Dreams', 'Emma Thompson', 'Ethereal watercolor series depicting the Australian coastline through soft, dreamlike washes of blue and turquoise.', 380.00, 'https://images.unsplash.com/photo-1547826039-bfc35e0f1ea8', 'Japanese Garden', 'Painting', '40cm x 60cm', 2024, false, 'NAR-2024-004', true, 'admin@53coxroad.com'),
(5,'Recycled Futures', 'David Kim', 'Large-scale sculpture assembled from reclaimed industrial metal, speaking to themes of sustainability and transformation.', 3500.00, 'https://images.unsplash.com/photo-1549887534-1541e9326642', 'Eden Garden', 'Sculpture', '180cm x 120cm x 90cm', 2023, true, 'NAR-2024-005', true, 'admin@53coxroad.com'),
(6,'Zen Vessels', 'Isabella Martinez', 'Set of three minimalist ceramic pieces inspired by Japanese tea ceremony traditions, featuring organic shapes and earth tones.', 650.00, 'https://images.unsplash.com/photo-1610701596007-11502861dcfa', 'Japanese Garden', 'Ceramics', 'Various sizes', 2024, false, 'NAR-2024-006', true, 'admin@53coxroad.com'),
(7,'Digital Horizons', 'James Wu', 'Photographic composite blending natural landscapes with abstract digital elements, questioning our perception of reality.', 890.00, 'https://images.unsplash.com/photo-1533158326339-7f3cf2404354', 'Studio', 'Photography', '90cm x 120cm', 2024, true, 'NAR-2024-007', true, 'admin@53coxroad.com'),
(8,'Morning Light', 'Emma Thompson', 'Delicate watercolor study of morning light filtering through eucalyptus trees along the Queensland coast.', 320.00, 'https://images.unsplash.com/photo-1547826039-bfc35e0f1ea8', 'Bamboo Garden', 'Painting', '35cm x 50cm', 2024, false, 'NAR-2024-008', true, 'admin@53coxroad.com'),
(9,'Connection Series #3', 'Sarah Chen', 'Part of an ongoing series exploring human connection in the digital age through layered abstract forms.', 980.00, 'https://images.unsplash.com/photo-1549887534-1541e9326642', 'Studio', 'Mixed Media', '100cm x 100cm', 2024, false, 'NAR-2024-009', true, 'admin@53coxroad.com'),
(10,'The Young Gentleman', 'Marcus Rivera', 'Classic oil portrait demonstrating masterful control of light and shadow in the tradition of the Old Masters.', 1800.00, 'https://images.unsplash.com/photo-1513364776144-60967b0f800f', 'Studio', 'Painting', '60cm x 80cm', 2024, false, 'NAR-2024-010', true, 'admin@53coxroad.com');



INSERT INTO exhibitions (id, title, description, start_date, end_date, status, location, featured_artists, image_url, created_by) VALUES
(1,'1,Summer Collection 2025', 'Celebrating Australian contemporary art with works from emerging and established artists. This exhibition brings together diverse voices exploring themes of identity, environment, and connection.', '2025-01-15', '2025-03-15', 'upcoming', 'Main Gallery', '{"Sarah Chen", "Emma Thompson", "James Wu"}', 'https://images.unsplash.com/photo-1561214115-f2f134cc4912', 'admin@53coxroad.com'),
(2,'Portraits of Australia', 'A journey through portraiture showcasing diverse faces of modern Australia. From classical oil paintings to contemporary interpretations, this exhibition celebrates the human face in all its diversity.', '2025-02-01', '2025-04-30', 'upcoming', 'North Wing', '{"Marcus Rivera"}', 'https://images.unsplash.com/photo-1577083300684-f23beab24ebb', 'admin@53coxroad.com'),
(3,'Earth & Metal', 'An exploration of sculpture and ceramic art that speaks to our relationship with natural materials and sustainability.', '2025-03-10', '2025-05-20', 'upcoming', 'Sculpture Garden', '{"David Kim", "Isabella Martinez"}', 'https://images.unsplash.com/photo-1579762715118-a6f1d4b934f1', 'admin@53coxroad.com'),
(4,'Coastal Visions', 'Emma Thompson''s solo exhibition featuring her latest watercolor works capturing Australia''s stunning coastlines.', '2025-02-15', '2025-04-15', 'upcoming', 'East Gallery', '{"Emma Thompson"}', 'https://images.unsplash.com/photo-1547826039-bfc35e0f1ea8', 'admin@53coxroad.com');



INSERT INTO events (id,title, type, description, date, start_time, end_time, capacity, tickets_sold, ticket_price, is_free, status, location, featured_artists, image_url, created_by) VALUES
(2,'Opening Night Gala', 'Exhibition Opening', 'Join us for the opening night of our Summer Collection with wine, canapés, artist talks, and live music. Meet the artists and be among the first to view this stunning collection.', '2025-01-15', '18:00', '21:00', 100, 0, 50.00, false, 'upcoming', 'Main Gallery', '{"Sarah Chen", "Emma Thompson", "James Wu"}', 'https://images.unsplash.com/photo-1492684223066-81342ee5ff30', 'admin@53coxroad.com'),
(3,'Artist Talk: Sarah Chen', 'Artist Talk', 'Intimate conversation with abstract artist Sarah Chen about her creative process, inspirations, and the stories behind her latest works.', '2025-01-22', '14:00', '15:30', 30, 0, 0.00, true, 'upcoming', 'Lecture Theatre', '{"Sarah Chen"}', 'https://images.unsplash.com/photo-1475721027785-f74eccf877e2', 'admin@53coxroad.com'),
(4,'Watercolor Workshop', 'Workshop', 'Learn coastal watercolor techniques with Emma Thompson. All materials included. Suitable for beginners and intermediate artists.', '2025-02-05', '10:00', '13:00', 15, 0, 75.00, false, 'upcoming', 'Studio Workshop Space', '{"Emma Thompson"}', 'https://images.unsplash.com/photo-1452860606245-08befc0ff44b', 'admin@53coxroad.com'),
(5,'Gallery Tour: Portraits of Australia', 'Gallery Tour', 'Guided tour of our Portraits exhibition with curator commentary and insights into the works and artists.', '2025-02-08', '11:00', '12:00', 20, 0, 0.00, true, 'upcoming', 'North Wing', '{"Marcus Rivera"}', 'https://images.unsplash.com/photo-1577083300684-f23beab24ebb', 'admin@53coxroad.com'),
(6,'Sculpture Workshop with David Kim', 'Workshop', 'Hands-on workshop exploring metalwork and assemblage techniques. Learn to create art from found objects with master sculptor David Kim.', '2025-03-12', '13:00', '17:00', 12, 0, 120.00, false, 'upcoming', 'Sculpture Garden', '{"David Kim"}', 'https://images.unsplash.com/photo-1579762715118-a6f1d4b934f1', 'admin@53coxroad.com'),
(7,'Photography Masterclass', 'Workshop', 'Digital photography and photo manipulation masterclass with James Wu. Bring your camera and laptop.', '2025-03-20', '09:00', '16:00', 10, 0, 150.00, false, 'upcoming', 'Digital Studio', '{"James Wu"}', 'https://images.unsplash.com/photo-1542038784456-1ea8e935640e', 'admin@53coxroad.com');



INSERT INTO gift_vouchers (id, voucher_code, voucher_type, amount, experience_type, purchaser_name, purchaser_email, recipient_name, recipient_email, personal_message, purchase_price, status, expiry_date, created_by) VALUES
(1,'CG-DEMO001', 'amount', 100.00, NULL, 'John Smith', 'john.smith@example.com', 'Jane Doe', 'jane.doe@example.com', 'Hope you enjoy a creative day at the gallery! Love, John', 100.00, 'active', '2026-01-01', 'john.smith@example.com'),
(2,'CG-DEMO002', 'experience', 140.00, 'couple', 'Alice Brown', 'alice.brown@example.com', 'Bob Wilson', 'bob.wilson@example.com', 'Happy Anniversary! Looking forward to a creative date together.', 140.00, 'active', '2026-01-01', 'alice.brown@example.com'),
(3,'CG-DEMO003', 'amount', 250.00, NULL, 'Michael Lee', 'michael.lee@example.com', 'Sarah Johnson', 'sarah.j@example.com', 'Congratulations on your graduation! Create something amazing!', 250.00, 'active', '2026-01-01', 'michael.lee@example.com'),
(4,'CG-DEMO004', 'experience', 80.00, 'solo', 'Emma Davis', 'emma.d@example.com', 'Tom Harris', 'tom.harris@example.com', 'Happy Birthday! Enjoy some creative time for yourself!', 80.00, 'active', '2026-01-01', 'emma.d@example.com');



INSERT INTO painting_station_bookings (id, booking_type, date, time_slot, station_numbers, participant_count, booker_name, booker_email, booker_phone, per_person_rate, special_requests, price, payment_status, status, duration_hours, created_by) VALUES
(1,'solo', '2025-01-20', '14:00', '{5}', 1, 'Jennifer White', 'jennifer.white@example.com', '0412345678', 80.00, 'First time painting, would appreciate some guidance', 80.00, 'paid', 'confirmed', 2.0, 'jennifer.white@example.com'),
(2,'couple', '2025-01-25', '10:00', '{3, 4}', 2, 'Robert Martinez', 'robert.m@example.com', '0423456789', 70.00, 'Anniversary celebration - can we have champagne?', 140.00, 'pending', 'pending', 2.5, 'robert.m@example.com'),
(3,'family', '2025-02-01', '11:00', '{7, 8, 9}', 3, 'Susan Taylor', 'susan.taylor@example.com', '0434567890', 55.00, 'Two adults and one teenager', 165.00, 'paid', 'confirmed', 2.5, 'susan.taylor@example.com'),
(4,'corporate', '2025-02-10', '09:00', '{1, 2, 3, 4, 5, 6}', 6, 'David Chen', 'david.chen@techcorp.com', '0445678901', 75.00, 'Team building for our marketing department', 450.00, 'paid', 'confirmed', 3.0, 'david.chen@techcorp.com');



INSERT INTO garden_bookings (id, garden_id, garden_name, date, start_time, end_time, duration_hours, guest_count, booker_name, booker_email, booker_phone, purpose, special_requests, reservation_fee, total_price, payment_status, status, created_by) VALUES
(1,'garden_001', 'Japanese Garden', '2025-01-28', '14:00', '17:00', 3.0, 20, 'Amanda Wilson', 'amanda.w@example.com', '0456789012', 'private_event', 'Small birthday celebration, would like tea service', 50.00, 500.00, 'paid', 'confirmed', 'amanda.w@example.com'),
(2,'garden_002', 'Rose Garden', '2025-02-14', '11:00', '15:00', 4.0, 30, 'Christopher Brown', 'chris.brown@example.com', '0467890123', 'photoshoot', 'Wedding photography session', 50.00, 770.00, 'pending', 'pending', 'chris.brown@example.com'),
(3,'garden_003', 'Bamboo Garden', '2025-02-05', '07:00', '09:00', 2.0, 10, 'Lisa Anderson', 'lisa.a@example.com', '0478901234', 'meditation', 'Yoga and meditation group session', 50.00, 330.00, 'paid', 'confirmed', 'lisa.a@example.com');



INSERT INTO portrait_commissions (id, artist_id, artist_name, style, size, contact_email, contact_phone, special_requests, total_price, deposit_paid, status, progress_percentage, progress_stage, estimated_completion, created_by) VALUES
(1,'artist_002', 'Marcus Rivera', 'Oil Painting', 'Medium (50x70cm)', 'jennifer.white@example.com', '0412345678', 'Portrait of my grandmother from a vintage photograph', 1200.00, 400.00, 'in_progress', 45, 'Base Colors', '2025-03-15', 'jennifer.white@example.com'),
(2,'artist_002', 'Marcus Rivera', 'Charcoal', 'Small (30x40cm)', 'michael.lee@example.com', '0423456789', 'Family portrait of three people', 800.00, NULL, 'pending_deposit', 0, 'Awaiting Start', '2025-04-01', 'michael.lee@example.com'),
(3,'artist_001', 'Sarah Chen', 'Mixed Media', 'Large (70x100cm)', 'david.chen@techcorp.com', '0445678901', 'Abstract portrait for corporate office', 1500.00, 500.00, 'deposit_paid', 10, 'Sketch Phase', '2025-04-20', 'david.chen@techcorp.com');



INSERT INTO art_rover_routes (id, name, description, states_covered, assigned_rover, recurrence_pattern, is_active, next_run_date, created_by) VALUES
(1,'Queensland Coastal Route', 'Monthly tour of Queensland coastal cities showcasing Australian art and taking portrait commissions', '{"QLD"}', 'Rover Alpha', 'monthly', true, '2025-02-01', 'admin@53coxroad.com'),
(2,'Victoria Metropolitan Loop', 'Bi-weekly circuit of Melbourne metro area and regional centers', '{"VIC"}', 'Rover Beta', 'biweekly', true, '2025-01-20', 'admin@53coxroad.com'),
(3,'NSW Capital Cities', 'Monthly route covering Sydney, Newcastle, and Wollongong', '{"NSW"}', 'Rover Alpha', 'monthly', true, '2025-02-10', 'admin@53coxroad.com'),
(4,'South Australia Explorer', 'Quarterly tour of SA including Adelaide and regional galleries', '{"SA"}', 'Rover Charlie', 'quarterly', true, '2025-03-01', 'admin@53coxroad.com');


INSERT INTO art_rover_tours (id, title, description, state, location_name, address, latitude, longitude, date, start_time, end_time, event_type, slots_available, slots_booked, rover_unit, status, is_recurring, route_id, contact_email, created_by) VALUES
(1,'Brisbane Riverside Art Exhibition', 'Discover contemporary Australian art along the Brisbane River. Free entry, artwork sales available on-site.', 'QLD', 'South Bank Parklands', '1 Grey Street, South Brisbane QLD 4101', -27.4748, 153.0178, '2025-01-15', '10:00', '18:00', 'exhibition', 50, 12, 'Rover Alpha', 'upcoming', true, 'route_qld_001', 'brisbane@53coxroad.com', 'admin@53coxroad.com'),
(2,'Melbourne Portrait Commission Day', 'Meet our artists and commission custom portraits. Book your consultation session today!', 'VIC', 'Federation Square', 'Corner Swanston & Flinders Streets, Melbourne VIC 3000', -37.8180, 144.9685, '2025-01-20', '09:00', '17:00', 'portrait_orders', 30, 18, 'Rover Beta', 'upcoming', false, NULL, 'melbourne@53coxroad.com', 'admin@53coxroad.com'),
(3,'Sydney Harbour Creative Workshop', 'Join us for a 2-hour watercolor workshop with stunning harbour views. All materials included.', 'NSW', 'Circular Quay', 'Alfred Street, Circular Quay NSW 2000', -33.8615, 151.2106, '2025-01-22', '14:00', '16:00', 'workshop', 20, 5, 'Rover Alpha', 'upcoming', false, NULL, 'sydney@53coxroad.com', 'admin@53coxroad.com'),
(4,'Adelaide Pop-Up Gallery', 'Monthly art showcase featuring local and touring artists. Wine and cheese provided.', 'SA', 'Adelaide Central Market', '44-60 Gouger Street, Adelaide SA 5000', -34.9312, 138.5980, '2025-02-01', '11:00', '19:00', 'pop_up_show', 100, 0, 'Rover Charlie', 'upcoming', true, 'route_sa_001', 'adelaide@53coxroad.com', 'admin@53coxroad.com'),
(5,'Perth Corporate Art Consultation', 'Private corporate event for office art selection and employee engagement activities.', 'WA', 'Elizabeth Quay', 'The Esplanade, Perth WA 6000', -31.9559, 115.8606, '2025-02-05', '09:00', '14:00', 'corporate', 60, 60, 'Rover Beta', 'upcoming', false, NULL, 'perth@53coxroad.com', 'admin@53coxroad.com'),
(6,'Gold Coast School Art Program', 'Interactive art education for high school students. Portfolio development focus.', 'QLD', 'Surfers Paradise Beach', 'The Esplanade, Surfers Paradise QLD 4217', -28.0023, 153.4145, '2025-02-10', '08:30', '15:00', 'school_visit', 80, 80, 'Rover Alpha', 'upcoming', false, NULL, 'goldcoast@53coxroad.com', 'admin@53coxroad.com'),
(7,'Hobart Waterfront Art Market', 'Bi-weekly art market showcasing Tasmanian artists and touring exhibits.', 'TAS', 'Salamanca Place', 'Salamanca Place, Battery Point TAS 7004', -42.8891, 147.3312, '2025-01-12', '10:00', '16:00', 'art_sales', 40, 8, 'Rover Charlie', 'active', true, 'route_tas_001', 'hobart@53coxroad.com', 'admin@53coxroad.com');



INSERT INTO artist_messages (id, artist_id, artist_name, sender_name, sender_email, subject, message, status, created_by) VALUES
(1,'artist_001', 'Sarah Chen', 'Robert Johnson', 'robert.j@example.com', 'Commission Inquiry', 'Hi Sarah, I saw your work at the Summer Collection and would love to discuss a commission piece for my office. Could we schedule a consultation?', 'sent', 'robert.j@example.com'),
(2,'artist_003', 'Emma Thompson', 'Michelle Adams', 'michelle.a@example.com', 'Workshop Question', 'I attended your watercolor workshop last month and loved it! Are you planning any advanced sessions in the future?', 'replied', 'michelle.a@example.com'),
(3,'artist_002', 'Marcus Rivera', 'James Peterson', 'james.p@example.com', 'Portrait Session', 'I''m interested in commissioning a family portrait. What is your availability for the next few months?', 'read', 'james.p@example.com');



INSERT INTO exhibition_bookings (id, exhibition_id, visitor_name, visitor_email, visitor_phone, preferred_date, preferred_time, party_size, notes, status, created_by) VALUES
(1,'exhibition_001', 'Thomas Anderson', 'thomas.a@example.com', '0489012345', '2025-01-20', '14:00', 2, 'Interested in contemporary abstract pieces', 'confirmed', 'thomas.a@example.com'),
(2,'exhibition_002', 'Patricia Williams', 'patricia.w@example.com', '0490123456', '2025-02-10', '11:00', 4, 'Family visit with two teenagers', 'confirmed', 'patricia.w@example.com'),
(3,'exhibition_001', 'Kevin Martinez', 'kevin.m@example.com', '0401234567', '2025-01-25', '15:00', 1, 'Art student researching contemporary Australian art', 'pending', 'kevin.m@example.com');



INSERT INTO event_bookings (id, event_id, attendee_name, attendee_email, attendee_phone, number_of_tickets, total_price, ticket_code, payment_status, status, created_by) VALUES
(1, 'event_001', 'Laura Thompson', 'laura.t@example.com', '0412345678', 2, 100.00, 'TKT-20250115-001', 'paid', 'confirmed', 'laura.t@example.com'),
(2, 'event_003', 'Daniel Kim', 'daniel.k@example.com', '0423456789', 1, 75.00, 'TKT-20250205-001', 'paid', 'confirmed', 'daniel.k@example.com'),
(3,'event_002', 'Sophie Anderson', 'sophie.a@example.com', '0434567890', 1, 0.00, 'TKT-20250122-001', 'free', 'confirmed', 'sophie.a@example.com'),
(4, 'event_006', 'Marcus Brown', 'marcus.b@example.com', '0445678901', 1, 150.00, 'TKT-20250320-001', 'pending', 'confirmed', 'marcus.b@example.com');



INSERT INTO collaborative_projects (id, title, description, owner_email, collaborators, status, art_style, tags, created_by) VALUES
(1,'Community Mural Project', 'Large-scale collaborative mural celebrating diversity in Australian art', 'sarah.chen@example.com', '{"emma.thompson@example.com", "james.wu@example.com"}', 'in_progress', 'Mixed Media', '{"community", "mural", "collaboration"}', 'sarah.chen@example.com'),
(2,'Digital Garden Series', 'Experimental digital art project combining photography and abstract painting', 'james.wu@example.com', '{"sarah.chen@example.com"}', 'in_progress', 'Digital', '{"digital", "experimental", "nature"}', 'james.wu@example.com'),
(3,'Coastal Memories', 'Collaborative watercolor series documenting Australia''s changing coastlines', 'emma.thompson@example.com', '{}', 'draft', 'Watercolor', '{"coastal", "environmental", "landscape"}', 'emma.thompson@example.com');



INSERT INTO wishlist (id, artwork_id, item_type, notes, notify_back_in_stock, notify_on_sale, price_when_added, created_by) VALUES
(1,'artwork_001', 'artwork', 'Would look perfect in my living room', true, true, 450.00, 'robert.j@example.com'),
(2,'artwork_002', 'artwork', 'Saving up for this piece', true, true, 1200.00, 'jennifer.white@example.com'),
(3,'artwork_007', 'artwork', 'Interested in this photographer''s work', true, false, 890.00, 'michael.lee@example.com');


INSERT INTO saved_postcards (id, station_name, station_image, message, recipient_name, sender_name, style, font, created_by) VALUES
(1,'Japanese Garden', 'https://images.unsplash.com/photo-1519552928903-5ebcd0d33c3b', 'Wishing you peace and tranquility on your journey', 'Mom', 'Sarah', 'vintage', 'serif', 'sarah.user@example.com'),
(2,'Rose Garden', 'https://images.unsplash.com/photo-1490750967868-88aa4486c946', 'Happy Anniversary! May our love continue to bloom.', 'My Love', 'Your Forever', 'romantic', 'script', 'robert.m@example.com');


commit;