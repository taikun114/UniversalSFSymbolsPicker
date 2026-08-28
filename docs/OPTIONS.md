# Available Options for UniversalSFSymbolsPicker

**English** | [日本語](OPTIONS-ja.md)

This page explains all the available options in UniversalSFSymbolsPicker and the differences between the setting values.

All available options and default values in UniversalSFSymbolsPicker are as follows. Default values are provided for non-required options, so there is no problem implementing without writing what you do not need to change.

| Parameter Name | Type | Default Value |
| :--- | :--- | :--- |
| [`isPresented`](#ispresented) | `Binding<Bool>` | - (Required) |
| [`selection`](#selection) | `Binding<String?>` | - (Required) |
| [`showAs`](#showas) | `SFSymbolPickerDisplayMode` | `.sheet` |
| [`controlBarPosition`](#controlbarposition) | `SFSymbolPickerControlBarPosition` | `.bottom` |
| [`showSearchBar`](#showsearchbar) | `Bool` | `true` |
| [`prompt`](#prompt) | `String?` | `nil` |
| [`searchText`](#searchtext) | `Binding<String>` | `.constant("")` |
| [`showCategoryPicker`](#showcategorypicker) | `Bool` | `true` |
| [`showCategorySectionLabel`](#showcategorysectionlabel) | `Bool` | `true` |
| [`categoryLabelVisibility`](#categorylabelvisibility) | `SFSymbolPickerCategoryLabelVisibility` | `.default` |
| [`categoryLabelStyle`](#categorylabelstyle) | `SFSymbolPickerCategoryLabelStyle` | `.both` |
| [`defaultCategory`](#defaultcategory) | `String` | `"all"` |
| [`includedCategories`](#includedcategories) | `[String]?` | `nil` |
| [`excludedCategories`](#excludedcategories) | `[String]?` | `nil` |
| [`customCategories`](#customcategories) | `[CustomCategory]` | `[]` |
| [`showIconName`](#showiconname) | `Bool` | `true` |
| [`excludeRestricted`](#excluderestricted) | `Bool` | `false` |
| [`iconScale`](#iconscale) | `Int` | `5` |
| [`iconSpacing`](#iconspacing) | `Int` | `5` |
| [`showRecents`](#showrecents) | `Bool` | `false` |
| [`maxRecents`](#maxrecents) | `Int` | `20` |
| [`renderingMode`](#renderingmode) | `SymbolRenderingMode` | `.monochrome` |
| [`isGradient`](#isgradient) | `Bool` | `false` |
| [`primaryColor`](#primarycolor--secondarycolor--tertiarycolor) | `Color` | `.primary` |
| [`secondaryColor`](#primarycolor--secondarycolor--tertiarycolor) | `Color?` | `nil` |
| [`tertiaryColor`](#primarycolor--secondarycolor--tertiarycolor) | `Color?` | `nil` |
| [`variableValue`](#variablevalue) | `Binding<Double?>` | `.constant(nil)` |
| [`sfSymbolsVersion`](#sfsymbolsversion) | `Double?` | `nil` |

## Core & Basics
### `isPresented`

**This is a required option.**\
Manages the presentation state of the sheet or popover.

When performing a full-screen transition using `NavigationLink`, specify `.constant(true)`.

### `selection`

**This is a required option.**\
Manages the state of the currently selected icon.

### `showAs`

Specifies the display mode.

The available options are:

- `.sheet` (Default)
  - Specify this when displaying as a sheet.
- `.popover`
  - Specify this when displaying in a way other than a sheet.

> [!NOTE]
> With `.sheet`, a toolbar and toolbar items are added for operation when displaying the sheet. On macOS, a custom bottom bar is added. In this mode, you can operate with an almost system-native layout, but the layout may break if displayed outside of a sheet.
>
> With `.popover`, a custom control bar (custom search bar and category picker button) is added instead of a toolbar. The layout is less likely to break even with various display methods.
>
> On tvOS, the layout does not change regardless of which you choose, but I recommend using `.popover` to match other platforms.

### `controlBarPosition`

![controlBarPosition](images/UniversalSFSymbolsPicker_controlBarPosition.webp)

Specifies the display position of the control bar (custom search bar and category picker button).

The available options are:

- `.bottom` (Default)
  - Places the control bar at the bottom.
- `.top`
  - Places the control bar at the top.

> [!NOTE]
> When displaying as a sheet on macOS, this option only affects the custom search bar. If `showSearchBar: false` is specified, changing this option will not affect the layout on macOS.
>
> On watchOS and tvOS, for operability reasons, this option is ignored, and the control bar is always displayed at the top.

## Search Related
### `showSearchBar`

![showSearchBar](images/UniversalSFSymbolsPicker_showSearchBar.webp)

Specifies whether to display the custom search bar provided by UniversalSFSymbolsPicker.

The available options are:

- `true` (Default)
  - Displays the custom search bar.
- `false`
  - Hides the custom search bar.

> [!NOTE]
> When displaying using a sheet or `NavigationLink`, etc., you can display the system standard search bar using the `.searchable` modifier.\
> In that case, since it will overlap with the custom search bar (two search bars will be displayed), specify `false` when using the `.searchable` modifier.

### `prompt`

Specifies the placeholder text to display in the search bar (Default: `nil`). Multilingual support is possible by specifying like `String(localized: "Text")`.

If nothing is specified, the default `Search Icons…` will be displayed.

### `searchText`

When using the search feature, it is necessary to bind a search keyword (Default: `.constant("")`).

Even if `showSearchBar: false` is specified, this is required if you are using the search feature (if not specified, search will not work).

## Categories
### `showCategoryPicker`

![showCategoryPicker](images/UniversalSFSymbolsPicker_showCategoryPicker.webp)

Specifies whether to display the picker for selecting categories.

The available options are:

- `true` (Default)
  - Displays the category picker.
- `false`
  - Hides the category picker.

### `showCategorySectionLabel`

![showCategorySectionLabel](images/UniversalSFSymbolsPicker_showCategorySectionLabel.webp)

Specifies whether to display section labels (headings) within the category picker.

> [!NOTE]
> This option is supported on iOS 18.0 or later, macOS 15.0 or later, tvOS 18.0 or later, watchOS 11.0 or later, and visionOS 2.0 or later. On earlier OS versions, this option is ignored.

The available options are:

- `true` (Default)
  - Displays section labels.
- `false`
  - Hides section labels.

### `categoryLabelVisibility`

![categoryLabelVisibility](images/UniversalSFSymbolsPicker_categoryLabelVisibility.webp)

Specifies the display visibility of the category picker's label.

The available options are:

- `.default` (Default)
  - Adjusts automatically depending on the platform, display mode, presence of search bar, etc.
- `.visible`
  - Always displays the label.
- `.hidden`
  - Always hides the label.

> [!NOTE]
> On watchOS, the label is always displayed regardless of this option.

### `categoryLabelStyle`

![categoryLabelStyle](images/UniversalSFSymbolsPicker_categoryLabelStyle.webp)

Specifies the display style of the label when the category picker's label is visible.

The available options are:

- `.both` (Default)
  - Displays both the label title `Category` and the selected category name, like `Category: All`.
- `.titleOnly`
  - Displays only the label title `Category`.
- `.nameOnly`
  - Displays only the selected category name, like `All`.

### `defaultCategory`

Specifies the category that is initially selected when the picker is opened (Default: `"all"`).

The available options are:

- `"all"` (Default)
  - Leaves `All` selected.
- `"communication"`
  - Leaves `Communication` selected.
- `"weather"`
  - Leaves `Weather` selected.
- `"maps"`
  - Leaves `Maps` selected.
- `"objectsandtools"`
  - Leaves `Objects & Tools` selected.
- `"devices"`
  - Leaves `Devices` selected.
- `"cameraandphotos"`
  - Leaves `Camera & Photos` selected.
- `"gaming"`
  - Leaves `Gaming` selected.
- `"connectivity"`
  - Leaves `Connectivity` selected.
- `"transportation"`
  - Leaves `Transportation` selected.
- `"automotive"`
  - Leaves `Automotive` selected.
- `"accessibility"`
  - Leaves `Accessibility` selected.
- `"privacyandsecurity"`
  - Leaves `Privacy & Security` selected.
- `"human"`
  - Leaves `Human` selected.
- `"home"`
  - Leaves `Home` selected.
- `"fitness"`
  - Leaves `Fitness` selected.
- `"nature"`
  - Leaves `Nature` selected.
- `"editing"`
  - Leaves `Editing` selected.
- `"textformatting"`
  - Leaves `Text Formatting` selected.
- `"media"`
  - Leaves `Media` selected.
- `"keyboard"`
  - Leaves `Keyboard` selected.
- `"commerce"`
  - Leaves `Commerce` selected.
- `"time"`
  - Leaves `Time` selected.
- `"health"`
  - Leaves `Health` selected.
- `"shapes"`
  - Leaves `Shapes` selected.
- `"arrows"`
  - Leaves `Arrows` selected.
- `"indices"`
  - Leaves `Indices` selected.
- `"math"`
  - Leaves `Math` selected.
- Custom Category ID
  - Leaves your own custom category added using the [`customCategories` option](#customcategories) selected.

### `includedCategories`

Specifies the IDs of the categories to be available in the picker as an array (Default: `nil`).\
In addition to system category IDs (like `"weather"`), you can also specify the `id` of custom categories.

When categories are specified, only the `All` category and the specified categories will be displayed, and icons included in other categories will also be excluded from the `All` category.

> [!NOTE]
> If you want to include all categories, you need to specify `nil` instead of `"all"` (or omit the option). Because the category ID `"all"` does not exist inside UniversalSFSymbolsPicker, if you specify it (unless you add a custom category with the ID `"all"`), it will be considered that a non-existent category has been specified, and no icons will be displayed.

### `excludedCategories`

Specifies the IDs of the categories to exclude from the entire picker as an array (Default: `nil`).\
In addition to system category IDs, you can also specify the `id` of custom categories.

When categories are specified, the specified categories are excluded from the list and also excluded from the `All` category.

> [!NOTE]
> When used in combination with the `includedCategories` option, the contents of the `excludedCategories` option take precedence. In other words, if you specify different categories for each, icons that are included in the categories specified by `includedCategories` and also included in the categories specified by `excludedCategories` (icons belonging to both categories) will be excluded.\
> For example, if you specify `["weather", "maps"]` for `includedCategories` and `["transportation"]` for `excludedCategories`, icons such as `car`, which are included in both the `maps` and `transportation` categories, will be excluded.
>
> You cannot exclude `"all"` (specifying it does nothing).

### `customCategories`

You can add your own custom categories (Default: `[]`).

Specify an array of `[CustomCategory]`.

The options that can be set for `CustomCategory` are as follows:

- `id` (`String` / Optional)
  - A unique identifier for the category (Default: `UUID().uuidString`). You can specify any string (e.g. `"my-custom-category"`), which is useful when using it in options like `defaultCategory` and `includedCategories`.
- `label` (`String` / **Required**)
  - The display name of the category shown in the category picker. Multilingual support is possible by specifying like `String(localized: "Display Name")`.
- `icon` (`String` / **Required**)
  - The icon name (SF Symbols icon name) of the category shown in the category picker.
- `symbols` (`[String]` / Optional)
  - Specifies the SF Symbols icon names to include in this category as an array (Default: `[]`).
- `systemCategories` (`[String]` / Optional)
  - Specifies the IDs of existing system categories (e.g. `"weather"`, `"nature"`) to merge and include in this category as an array (Default: `[]`).
- `excludedSymbols` (`[String]` / Optional)
  - Specifies the icon names to exclude from this category as an array. Useful when removing some icons from `systemCategories` (Default: `[]`).

> [!NOTE]
> The icon names specified in `symbols` and `excludedSymbols`, etc., are all processed through the internal automatic resolution feature.\
> Therefore, for icon names with aliases (for example, `a` and `character`, etc.), even if you specify an old icon name or a new icon name, if the OS of the execution environment supports that icon, it will be automatically resolved to the newest compatible icon name and displayed.\
> Note that if you specify a new icon name that the OS of the execution environment does not support or if a non-existent icon name is entered, the `questionmark.square.dashed` icon (a question mark enclosed in a dashed square) will be displayed instead.
>
> Even if you are restricting the icons to be displayed using the global [`includedCategories`](#includedcategories) or [`excludedCategories`](#excludedcategories) options, restricted icons directly specified in the `symbols` option of a custom category will override the global exclusion settings and be displayed within the category as exceptions. However, they will not be displayed in `All`, but only within the specified custom category.

#### Example

```swift
let myCustomCategories: [CustomCategory] = [
    // Specify any string as an ID and specify particular icons to create a category
    CustomCategory(
        id: "my-favorites",
        label: "Favorites",
        icon: "star.fill",
        symbols: ["star", "star.fill", "heart", "heart.fill"]
    ),
    // Omit the ID to automatically assign a UUID, and in addition to adding icons, merge existing system categories and exclude specific icons
    CustomCategory(
        label: "Weather & Nature & Star Fill",
        icon: "leaf",
        symbols: ["star.fill"],
        systemCategories: ["weather", "nature"],
        excludedSymbols: ["tornado"]
    )
]

SFSymbolPicker(
    isPresented: $isPresented,
    selection: $selection,
    customCategories: myCustomCategories
)
```

## Display & Layout
### `showIconName`

![showIconName](images/UniversalSFSymbolsPicker_showIconName.webp)

Specifies whether to display the names of the icons.

- `true` (Default)
  - Displays icon names.
- `false`
  - Hides icon names.

> [!NOTE]
> When icon names are hidden, each icon will be displayed in a square grid.

### `excludeRestricted`

![excludeRestricted](images/UniversalSFSymbolsPicker_excludeRestricted.webp)

Specifies whether to exclude restricted icons, such as Apple's trademarks and service names.

- `false` (Default)
  - Displays all icons.
- `true`
  - Excludes restricted icons from the list.

> [!NOTE]
> Even if set to `true`, restricted icons directly specified in the `symbols` option of a custom category are treated as exceptions and displayed without being excluded.

### `iconScale`

![iconScale](images/UniversalSFSymbolsPicker_iconScale.webp)

Specifies the size of the icons in the range of `1` to `10` (Default: `5`).

A larger number makes the icons larger.

> [!NOTE]
> If a number outside the range is entered, it will fall back to the default of `5`.
>
> This option can be used in combination with `iconSpacing`.

### `iconSpacing`

![iconSpacing](images/UniversalSFSymbolsPicker_iconSpacing.webp)

Specifies the size of the padding between icons in the range of `1` to `10` (Default: `5`).

A larger number makes the spacing between icons wider.

> [!NOTE]
> If a number outside the range is entered, it will fall back to the default of `5`.
>
> This option can be used in combination with `iconScale`.

### `showRecents`

![showRecents](images/UniversalSFSymbolsPicker_showRecents.webp)

Specifies whether to display the history items of recently used icons.

The available options are:

- `false` (Default)
  - Does not display recently used icons.
- `true`
  - Displays recently used icons at the top of the picker.

> [!NOTE]
> When set to `false`, the history is not updated even if an icon is selected.

### `maxRecents`

![maxRecents](images/UniversalSFSymbolsPicker_maxRecents.webp)

Specifies the maximum number of recently used icons to save and display with a number of `1` or more (Default: `20`).

> [!NOTE]
> If a number of `0` or less is entered, it will fall back to the default of `20`.
>
> If it is set smaller than the number of histories already saved, the overflowed histories will be deleted.

## Styling
### `renderingMode`

![renderingMode](images/UniversalSFSymbolsPicker_renderingMode.webp)

Specifies the rendering mode of the icons.

The available options are:

- `.monochrome` (Default)
  - Renders in monochrome.
- `.hierarchical`
  - Renders hierarchically.
- `.palette`
  - Renders as a palette. The color for each layer can be specified with [`primaryColor` / `secondaryColor` / `tertiaryColor`](#primarycolor--secondarycolor--tertiarycolor).
- `.multicolor`
  - Renders in multicolor.

### `isGradient`

![isGradient](images/UniversalSFSymbolsPicker_isGradient.webp)

Specifies whether to apply a gradient to the icons.

> [!NOTE]
> This option is supported on iOS 26.0 or later, macOS 26.0 or later, tvOS 26.0 or later, watchOS 26.0 or later, and visionOS 26.0 or later. On earlier OS versions, this option is ignored.

- `false` (Default)
  - Renders with a flat color.
- `true`
  - Renders by applying a gradient.

### `primaryColor` / `secondaryColor` / `tertiaryColor`

Specifies the colors of the icons.

- `primaryColor` (Default: `.primary`)
  - Used as the base color in all rendering modes.
- `secondaryColor` (Default: `nil`)
  - Used as the secondary color in supported rendering modes, such as `.hierarchical` and `.palette`.
- `tertiaryColor` (Default: `nil`)
  - Used as the tertiary color in supported rendering modes, such as `.palette`.

### `variableValue`

![variableValue](images/UniversalSFSymbolsPicker_variableValue.webp)

Binds a value to variably render the corresponding icon (Default: `.constant(nil)`).

It can be specified in the range of `0.0` to `1.0`, and dynamically changes the display of variable value supported icons in real-time, such as battery level or gauges.

## Advanced
### `sfSymbolsVersion`

Specify this to restrict the version of SF Symbols to be displayed (Default: `nil`).

If you specify a particular version (e.g., `5.0`), only icons up to that version will be displayed. For icons whose names have been changed in subsequent versions, the new name will be used if the OS supports it.

When using custom categories to control the icons to be displayed, even if new icons are added due to updates to SF Symbols or UniversalSFSymbolsPicker, restricting the version here can fix the icons displayed in the picker so that they do not change.
