# Discourse Surveys

A comprehensive Discourse plugin for creating interactive surveys with multiple field types. This plugin allows you to embed surveys directly into your posts and collect structured responses from your community members.

## Features

- **7 Different Field Types**: Radio buttons, checkboxes, dropdowns, text areas, number selection, star ratings, and thumbs up/down
- **Required/Optional Fields**: Mark fields as required to ensure completion
- **Emoji Support**: Use emojis in your survey options
- **Markdown Support**: Rich text formatting in questions and options
- **User Authentication**: Automatic login prompts for anonymous users
- **Response Tracking**: Prevents duplicate submissions from the same user
- **Permission Aware**: Respects topic and category permissions
- **Mobile Responsive**: Works seamlessly on all devices

## Installation

Follow the [Install a Plugin](https://meta.discourse.org/t/install-a-plugin/19157) guide from Discourse Meta using:

```bash
git clone https://github.com/discourse-org/discourse-surveys.git
```

After installation, enable the plugin in your admin settings:
- Navigate to **Admin → Plugins**
- Find **discourse-surveys** and enable it
- Set `surveys_enabled` to `true` in site settings

## Usage

### Basic Survey Structure

All surveys must be wrapped in `[survey]` tags:

```markdown
[survey name="my-survey" title="Customer Feedback Survey"]
<!-- Survey fields go here -->
[/survey]
```

### Survey Attributes

- `name`: Unique identifier for the survey (defaults to "survey")
- `title`: Optional title displayed at the top of the survey
- `public`: Set visibility (future feature)
- `status`: Survey status (future feature)

### Field Types

#### 1. Radio Buttons (Single Choice)

```markdown
[radio question="What is your favorite color?"]
- Red
- Blue
- Green
- Yellow
[/radio]
```

#### 2. Checkboxes (Multiple Choice)

```markdown
[checkbox question="Which features do you use? (Select all that apply)"]
- Email notifications
- Mobile app
- Desktop notifications
- API access
[/checkbox]
```

#### 3. Dropdown Selection

```markdown
[dropdown question="What is your age group?"]
- Under 18
- 18-24
- 25-34
- 35-44
- 45-54
- 55+
[/dropdown]
```

#### 4. Text Area (Long Form Text)

```markdown
[textarea question="Please provide detailed feedback:" required="false"]
[/textarea]
```

#### 5. Number Selection

```markdown
[number question="Rate this feature from 1-10:" min="1" max="10"]
[/number]
```

#### 6. Star Rating

```markdown
[star question="How would you rate your overall experience?"]
[/star]
```

#### 7. Thumbs Up/Down

```markdown
[thumbs question="Would you recommend this to others?"]
[/thumbs]
```

### Field Attributes

All field types support these attributes:

- `question`: The question text (required)
- `required`: Whether the field must be filled (`true`/`false`, defaults to `true`)
- `min`: Minimum value for number fields
- `max`: Maximum value for number fields

### Complete Example

```markdown
[survey name="product-feedback" title="Product Feedback Survey"]

[radio question="How did you hear about us?"]
- Search engine
- Social media
- Friend recommendation
- Advertisement
- Other
[/radio]

[checkbox question="Which features are most important to you?"]
- Speed
- Security
- User interface
- Customer support
- Price
[/checkbox]

[dropdown question="How often do you use our product?"]
- Daily
- Weekly
- Monthly
- Rarely
[/dropdown]

[star question="Overall satisfaction rating:"]
[/star]

[number question="How likely are you to recommend us? (1-10)"]
[/number]

[textarea question="Any additional comments?" required="false"]
[/textarea]

[thumbs question="Would you purchase again?"]
[/thumbs]

[/survey]
```

## Advanced Usage

### Using Emojis in Options

```markdown
[radio question="Choose your favorite animal:"]
- 🐈 Cat
- 🐶 Dog
- 🐦 Bird
- 🐠 Fish
[/radio]
```

### Markdown Formatting in Questions

You can use standard Markdown formatting in your survey questions:

```markdown
[radio question="Which **programming language** do you prefer?"]
- JavaScript
- Python
- Ruby
- Go
[/radio]

[checkbox question="Select your *favorite* features:"]
- Speed
- Security
- Ease of use
[/checkbox]

[textarea question="Please read our [guidelines](https://example.com) and provide feedback:"]
[/textarea]
```

Supported formatting:
- **Bold**: `**text**` or `__text__`
- *Italic*: `*text*` or `_text_`
- ~~Strikethrough~~: `~~text~~`
- `Inline code`: `` `code` ``
- [Links](https://example.com): `[text](url)`

### Mixed Required and Optional Fields

```markdown
[survey name="mixed-survey"]

[radio question="What is your role?" required="true"]
- Developer
- Designer
- Manager
- Other
[/radio]

[textarea question="Any additional thoughts?" required="false"]
[/textarea]

[/survey]
```

## User Experience

### For Survey Creators
1. Write your survey using the markdown syntax above
2. Post it in any topic where you have posting permissions
3. The survey will automatically appear as an interactive form
4. Users can submit responses immediately

### For Survey Respondents
1. Visit the topic containing the survey
2. If not logged in, you'll be prompted to sign in when attempting to respond
3. Fill out the required fields (optional fields can be skipped)
4. Click "Submit" to save your response
5. Once submitted, you'll see a confirmation message and cannot submit again

## Permissions and Security

- **Login Required**: Anonymous users must log in before submitting responses
- **One Response Per User**: Each user can only submit one response per survey
- **Topic Permissions**: Users must have read access to the topic to view surveys
- **Posting Permissions**: Users must have posting permissions in the topic to submit responses
- **Archived Topics**: Surveys in archived topics cannot accept new responses
- **Deleted Posts**: Surveys in deleted posts are no longer accessible

## Limitations

- Only one survey is allowed per post
- Survey structure cannot be modified after receiving responses
- All survey field questions must be unique within a single survey
- Survey field questions cannot be blank

## Technical Details

### Database Schema
The plugin creates four main database tables:
- `surveys`: Main survey records
- `survey_fields`: Individual fields within surveys
- `survey_field_options`: Options for choice-based fields
- `survey_responses`: User responses to survey fields

### Styling
The plugin includes responsive CSS that adapts to your theme. Custom styling can be added by targeting these CSS classes:
- `.survey` - Main survey container
- `.survey-field` - Individual field wrapper
- `.field-[type]` - Specific field type containers
- `.submit-response` - Submit button

## Feedback and Support

If you have issues or suggestions for the plugin, please bring them up on [Discourse Meta](https://meta.discourse.org).