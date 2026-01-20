# Demo Type System - Quick Reference

## Overview

Created **8 demonstration types** extending `core_sysobject` to showcase the Hitorro type system capabilities.

## Type Hierarchy

```
core_sysobject (base type)
├── id (core_id)
├── times (core_dates)
├── title (core_mls)
├── body (core_mls)
└── description (core_mls)

Extended by:
├── demo_article (News & Blog Content)
├── demo_product (E-Commerce Products)
├── demo_person (People Profiles)
├── demo_document (Document Management)
├── demo_event (Calendar Events)
├── demo_ticket (Support Tickets)
├── demo_recipe (Cooking Recipes)
└── demo_property (Real Estate Listings)
```

## Quick Type Reference

| Type | Domain | Key Fields | Use Case |
|------|--------|------------|----------|
| **demo_article** | Content | author, publication, tags, content | News, blogs, articles |
| **demo_product** | E-commerce | sku, price, brand, in_stock | Product catalogs |
| **demo_person** | HR/CRM | first_name, last_name, email, skills | Employee directories, contacts |
| **demo_document** | DMS | filename, version, author, checksum | Document management |
| **demo_event** | Calendar | start_date, end_date, attendees, location | Event management |
| **demo_ticket** | Support | ticket_number, status, priority, assigned_to | Help desk, issue tracking |
| **demo_recipe** | Food | cuisine, ingredients, instructions, cook_time | Recipe sites, meal planning |
| **demo_property** | Real Estate | address, price, bedrooms, square_feet | Property listings, MLS |

## Files Created

### Type Definitions (JSON)
- `config/types/demo_article.json`
- `config/types/demo_product.json`
- `config/types/demo_person.json`
- `config/types/demo_document.json`
- `config/types/demo_event.json`
- `config/types/demo_ticket.json`
- `config/types/demo_recipe.json`
- `config/types/demo_property.json`

### Test Data (NDJson)
- `demo-data-articles.ndjson` (3 articles)
- `demo-data-products.ndjson` (3 products)
- `demo-data-people.ndjson` (3 people)
- `demo-data-properties.ndjson` (3 properties)
- `demo-data-tickets.ndjson` (3 tickets)

### Documentation
- `DEMO_TYPES_GUIDE.md` - Comprehensive guide with details
- `DEMO_TYPES_SUMMARY.md` - This file (quick reference)

### Test Scripts
- `test-demo-types.sh` - Test all demo types

## Testing

### Run All Tests
```bash
./test-demo-types.sh
```

### Test Individual Type
```bash
curl -X POST "http://localhost:8080/api/jvs/enrich/stream?tags=ner,segmented" \
  -H "Content-Type: application/octet-stream" \
  --data-binary @demo-data-articles.ndjson \
  -o output.ndjson
```

### View Type Definition
```bash
curl http://localhost:8080/api/jvs/types/demo_article | python3 -m json.tool
```

### List All Types
```bash
curl http://localhost:8080/api/jvs/types
```

## Type System Features

### 1. Multi-Language Support (core_mls)
Every text field can contain multiple languages with automatic NLP enrichment:
- **Sentence segmentation**: Breaks text into sentences
- **Named Entity Recognition**: Extracts people, places, organizations
- **Part-of-speech tagging**: Linguistic analysis
- **Text classification**: Categorizes content

### 2. Inheritance
All types inherit from `sysobject`:
- Unique ID system (domain + did)
- Timestamp tracking (created, modified)
- Multi-language title, body, description

### 3. Dynamic Fields
Computed fields that auto-populate:
- `full_name` from first + last name
- `id` from domain + did
- `clean` text (HTML scrubbing)
- `segmented_ner` (entity extraction)

### 4. Vector Fields
Arrays of values:
- Tags, categories, skills
- Multiple emails, phones
- Image URLs
- Attendees, amenities

### 5. Type Safety
Schema validation ensures:
- Required fields are present
- Types are correct
- References are valid

## Enrichment Tags

Use these tags with the enrichment endpoints:

| Tag | Function | Example Output |
|-----|----------|----------------|
| `basic` | Basic indexing | Standard fields |
| `ner` | Named Entity Recognition | Locations, people, orgs |
| `segmented` | Sentence segmentation | Array of sentences |
| `answers` | Text classification | Categories, topics |
| `pos` | Part-of-speech tagging | Linguistic tags |
| `parsed` | Parsing/chunking | Syntax trees |
| `hash` | Normalization hashes | Deduplication |

Example:
```bash
?tags=ner,segmented,answers
```

## Sample Enriched Output

Input:
```json
{"ht_type":"demo_article","title":{"mls":[{"text":"Tech Giant in San Francisco"}]}}
```

Enriched (with `tags=ner,segmented`):
```json
{
  "ht_type":"demo_article",
  "title":{
    "mls":[{
      "text":"Tech Giant in San Francisco",
      "clean":"Tech Giant in San Francisco",
      "segmented":["Tech Giant in San Francisco"],
      "segmented_ner":"Tech Giant in <LOCATION>San Francisco</LOCATION>",
      "lang":"en"
    }]
  }
}
```

## Common Use Cases

### Content Management
- **Articles**: News aggregation, blog platforms
- **Documents**: Knowledge bases, DMS systems

### E-Commerce
- **Products**: Catalogs, inventory, price monitoring
- **Properties**: Real estate, rentals

### People & Collaboration
- **Person**: CRM, HR systems, directories
- **Event**: Scheduling, conferences, meetings
- **Ticket**: Support, bug tracking, ITSM

### Specialized Domains
- **Recipe**: Cooking sites, meal planning
- (Easy to add more: legal documents, medical records, etc.)

## Creating Custom Types

Follow this pattern:

```json
{
  "name": "your_type",
  "description": "What this type represents",
  "super": "sysobject",
  "fields": [
    {
      "name": "custom_field",
      "type": "core_string"
    },
    {
      "name": "multi_value",
      "type": "core_string",
      "vector": true
    },
    {
      "name": "rich_text",
      "type": "core_mls"
    }
  ]
}
```

## Next Steps

1. ✅ Types are defined in `config/types/demo_*.json`
2. ✅ Test data is ready in `demo-data-*.ndjson`
3. ✅ Test script is ready: `./test-demo-types.sh`
4. 🔄 Start your Spring Boot app
5. 🔄 Run tests to see enrichment in action
6. 🔄 Create your own custom types
7. 🔄 Build applications using these types

## Architecture Benefits

✅ **Composable**: Mix and match primitive types  
✅ **Multi-lingual**: Native i18n support  
✅ **Rich NLP**: Automatic text enrichment  
✅ **Extensible**: Add fields without breaking compatibility  
✅ **Type-safe**: Schema validation  
✅ **Dynamic**: Computed fields  
✅ **Streaming**: Process millions of objects efficiently  

For detailed information, see `DEMO_TYPES_GUIDE.md`.
