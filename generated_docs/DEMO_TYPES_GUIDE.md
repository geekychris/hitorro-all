# Demo Type System Examples

## Overview

I've created **8 demonstration types** that extend `core_sysobject` to showcase different real-world use cases. Each type inherits the base fields from `sysobject` (id, times, title, body, description) and adds domain-specific fields.

## Type System Architecture

### Base Type: `core_sysobject`
All demo types inherit from `sysobject` which provides:
- **id** (core_id): Unique identifier with domain, did, and computed id/hash
- **times** (core_dates): Created and modified timestamps
- **title** (core_mls): Multi-language title field
- **body** (core_mls): Multi-language body content
- **description** (core_mls): Multi-language description

### Multi-Language Support (core_mls)
The `core_mls` type contains a vector of `core_mlselem` which provides:
- **lang**: Language code (e.g., "en", "es", "fr")
- **text**: Raw text with i18n support
- **clean**: HTML-scrubbed text (dynamic field)
- **segmented**: Sentence segmentation (dynamic field)
- **segmented_ner**: Named Entity Recognition (dynamic field)
- **segmented_answers**: Text classification (dynamic field)
- **pos**: Part-of-speech tagging (dynamic field)
- Various hash and normalization fields

This rich structure enables powerful NLP enrichment on all text fields.

## Demo Types

### 1. **demo_article** - News & Blog Content
News articles, blog posts, or editorial content.

**Additional Fields:**
- `author`: Article author name
- `publication`: Publication name
- `published_date`: Publication date
- `category`: Article categories (vector)
- `tags`: Content tags (vector)
- `content`: Full article content (multi-language)
- `excerpt`: Short excerpt (multi-language)
- `source_url`: Original article URL

**Use Cases:**
- News aggregation platforms
- Blog management systems
- Content recommendation engines
- Editorial workflows

### 2. **demo_product** - E-Commerce Products
Product catalog with specifications, pricing, and inventory.

**Additional Fields:**
- `sku`: Stock Keeping Unit
- `brand`: Product brand
- `category`: Product categories (vector)
- `price`: Price in cents/smallest currency unit
- `currency`: Currency code (USD, EUR, etc.)
- `in_stock`: Availability flag
- `quantity`: Available quantity
- `specifications`: Detailed specs (multi-language)
- `images`: Product image URLs (vector)
- `reviews_count`: Number of reviews
- `rating`: Average rating

**Use Cases:**
- E-commerce platforms
- Product comparison sites
- Inventory management
- Price monitoring

### 3. **demo_person** - People Profiles
Person profiles with contact info, skills, and biography.

**Additional Fields:**
- `first_name`: First name
- `last_name`: Last name
- `full_name`: Computed full name (dynamic field)
- `email`: Email addresses (vector)
- `phone`: Phone numbers (vector)
- `birth_date`: Date of birth
- `biography`: Personal bio (multi-language)
- `skills`: Skills/expertise (vector)
- `social_profiles`: Social media URLs (vector)
- `profile_image`: Profile photo URL

**Use Cases:**
- CRM systems
- Employee directories
- Professional networking
- Contact management

### 4. **demo_document** - Document Management
Documents with version control and metadata.

**Additional Fields:**
- `filename`: Original filename
- `file_type`: MIME type or extension
- `file_size`: Size in bytes
- `version`: Version number/string
- `author`: Document author
- `department`: Owning department
- `content`: Full-text content (multi-language)
- `keywords`: Keywords/tags (vector)
- `classification`: Security classification
- `checksum`: File integrity hash
- `download_url`: Download URL

**Use Cases:**
- Document management systems (DMS)
- Knowledge bases
- Compliance tracking
- Version control

### 5. **demo_event** - Calendar Events
Events with scheduling, location, and attendees.

**Additional Fields:**
- `start_date`: Event start time
- `end_date`: Event end time
- `location`: Location name
- `location_details`: Detailed location info (multi-language)
- `organizer`: Event organizer
- `attendees`: List of attendees (vector)
- `event_type`: Type of event (conference, meeting, etc.)
- `capacity`: Maximum capacity
- `registration_url`: Registration page URL
- `virtual_link`: Virtual meeting link
- `agenda`: Event agenda (multi-language)

**Use Cases:**
- Event management platforms
- Conference scheduling
- Meeting coordination
- Calendar systems

### 6. **demo_ticket** - Support Tickets
Issue tracking and support ticket management.

**Additional Fields:**
- `ticket_number`: Unique ticket ID
- `status`: Current status (open, in-progress, closed)
- `priority`: Priority level (low, medium, high, critical)
- `category`: Issue category
- `assigned_to`: Assigned agent/team
- `reporter`: Person who reported
- `issue`: Issue description (multi-language)
- `resolution`: Resolution notes (multi-language)
- `tags`: Categorization tags (vector)
- `due_date`: Due date
- `closed_date`: Resolution date
- `attachments`: Attachment URLs (vector)

**Use Cases:**
- Help desk systems
- Bug tracking
- IT service management
- Customer support

### 7. **demo_recipe** - Cooking Recipes
Recipes with ingredients, instructions, and nutrition.

**Additional Fields:**
- `cuisine`: Cuisine type (Italian, Mexican, etc.)
- `course`: Course type (appetizer, main, dessert)
- `prep_time`: Preparation time (minutes)
- `cook_time`: Cooking time (minutes)
- `servings`: Number of servings
- `difficulty`: Difficulty level
- `ingredients`: Ingredient list (multi-language)
- `instructions`: Cooking steps (multi-language)
- `dietary_tags`: Dietary labels (vector: vegan, gluten-free, etc.)
- `calories`: Calorie count
- `images`: Recipe photos (vector)
- `chef`: Recipe author/chef

**Use Cases:**
- Recipe websites
- Meal planning apps
- Cooking instruction platforms
- Nutritional databases

### 8. **demo_property** - Real Estate
Property listings with location, features, and pricing.

**Additional Fields:**
- `listing_id`: MLS or internal listing ID
- `property_type`: Type (house, apartment, condo, etc.)
- `address`: Street address
- `city`: City
- `state`: State/province
- `zip_code`: Postal code
- `country`: Country
- `price`: Listing price
- `bedrooms`: Number of bedrooms
- `bathrooms`: Number of bathrooms
- `square_feet`: Total area
- `year_built`: Construction year
- `features`: Property features (multi-language)
- `amenities`: Amenities list (vector)
- `images`: Property photos (vector)
- `virtual_tour`: Virtual tour URL
- `agent`: Listing agent
- `status`: Listing status (active, pending, sold)

**Use Cases:**
- Real estate platforms
- MLS systems
- Property search engines
- Rental marketplaces

## Testing the Types

### Using the REST API

All types can be enriched using the existing endpoints:

```bash
# Single object enrichment
curl -X POST "http://localhost:8080/api/jvs/enrich" \
  -H "Content-Type: application/json" \
  -d '{
    "json": "{\"ht_type\":\"demo_article\",\"title\":{\"mls\":[{\"text\":\"Breaking News from San Francisco\"}]}}",
    "tags": "ner,segmented"
  }'

# Streaming enrichment (NDJson)
curl -X POST "http://localhost:8080/api/jvs/enrich/stream?tags=ner,answers" \
  -H "Content-Type: application/octet-stream" \
  --data-binary @demo-articles.ndjson
```

### Sample Data Files

See the `demo-data-*.ndjson` files for ready-to-use test data for each type.

## Type System Features Demonstrated

### 1. **Inheritance**
All types extend `sysobject`, inheriting id, times, and multi-language fields.

### 2. **Multi-Language Fields** (core_mls)
Fields like `title`, `body`, `content`, `biography` support multiple languages with automatic NLP enrichment:
- Sentence segmentation
- Named Entity Recognition (NER)
- Part-of-speech tagging
- Text classification

### 3. **Vector Fields**
Fields marked with `"vector": true` can hold multiple values:
- `tags`, `category`, `skills`, `attendees`, etc.

### 4. **Dynamic Fields**
Computed fields that derive from other fields:
- `full_name` (computed from first_name + last_name in demo_person)
- `clean` (HTML scrubbing in mlselem)
- `segmented_ner` (NER extraction in mlselem)

### 5. **Primitive Types**
Uses core primitive types:
- `core_string`: Text fields
- `core_long`: Numeric fields (price, quantity, ratings)
- `core_boolean`: Flags (in_stock)
- `core_date`: Timestamps
- `core_url`: URLs

## Querying Types

### List All Types
```bash
curl http://localhost:8080/api/jvs/types
```

### Get Type Definition
```bash
curl http://localhost:8080/api/jvs/types/demo_article
```

## Enrichment Tags

When enriching these types, you can use various tags:
- **basic**: Basic indexing fields
- **ner**: Named Entity Recognition
- **segmented**: Sentence segmentation
- **answers**: Text classification
- **pos**: Part-of-speech tagging
- **parsed**: Parsing/chunking
- **hash**: Normalization hashes

Example:
```bash
curl -X POST "http://localhost:8080/api/jvs/enrich/stream?tags=ner,segmented,answers" \
  -H "Content-Type: application/octet-stream" \
  --data-binary @demo-properties.ndjson
```

## Next Steps

1. **Test the types**: Use the sample data files to test enrichment
2. **Create custom types**: Follow these patterns to create your own types
3. **Add dynamic fields**: Implement custom mappers for domain-specific computations
4. **Extend with groups**: Add indexing and enrichment group definitions
5. **Build applications**: Use these types in your Spring Boot application

## Type System Advantages

✅ **Composable**: Build complex types from simpler ones  
✅ **Multi-lingual**: Native support for internationalization  
✅ **Rich NLP**: Automatic text enrichment with NER, segmentation, etc.  
✅ **Extensible**: Add new fields and types without breaking existing ones  
✅ **Type-safe**: Schema validation ensures data consistency  
✅ **Dynamic**: Computed fields reduce redundancy and ensure consistency  
