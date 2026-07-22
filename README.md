# UniversalSFSymbolsPicker

**English** | [日本語](docs/README-ja.md)

![UniversalSFSymbolsPicker](docs/images/UniversalSFSymbolsPicker.webp)

UniversalSFSymbolsPicker is a Swift package that allows you to easily implement a highly customizable SF Symbols picker available across a wide range of platforms.

## Features

- **✅ Simple and user-friendly design**
  - Designed to be easy to use with neatly arranged icons and highlighting of the currently selected icon.
- **📱 Supports a wide range of platforms**
  - You can integrate UniversalSFSymbolsPicker into your app on various devices.
- **🖼️ Selectable display modes**
  - You can customize the display mode according to the situation, such as a sheet or popover.
- **🚀 Fast performance with pagination support**
  - Operates extremely fast because it does not load all icons at once from the beginning.
- **🔍 Fast search functionality**
  - You can easily find the desired icon from among all the icons.
- **🕒 Recently used icons history feature**
  - You can display a history of recently selected icons and find frequently used icons from the history.
- **🔒 Exclusion of restricted icons**
  - You can exclude icons that have usage restrictions, such as Apple's trademarks and service names.
- **🌐 Proper exclusion of icons by locale and variant (shows original only)**
  - Variant icons that differ by region or language are excluded, and only the original icons that automatically switch to the optimal display for each region or language are shown.
- **🗄️ Supports filtering by category**
  - You can filter only by category, making it easy to find the desired icon.
- **📝 Supports adding custom categories**
  - You can select only the perfect icons for the app you want to integrate and add them as custom categories.
- **🎨 Supports various rendering modes and variable value displays**
  - In addition to flat display, you can change the display color and display variable icons based on numerical values.
- **🎛️ Highly advanced customization features**
  - Various customization options are available, allowing you to customize it to the optimal state for the app you want to integrate.
- **🪄 Icon name resolution feature by version**
  - The name is automatically resolved and changed to the latest version corresponding to the OS, so there is no need to worry about accidentally using old deprecated names.
- **🔤 Multilingual support**
  - It supports many languages and is designed to make adding more languages easy.

## Supported Platforms

UniversalSFSymbolsPicker supports the following platforms and versions:

- iOS / iPadOS 17.0 or later
- macOS 14.0 or later
- visionOS 1.0 or later
- watchOS 10.0 or later
- tvOS 17.0 or later

## Installation

You can easily install it using Swift Package Manager.

1. Open `Add Package Dependencies…` in the Xcode `File` menu, or click the `+` button in the `Package Dependencies` tab of your project.
2. Enter `https://github.com/taikun114/UniversalSFSymbolsPicker.git` in the search field.
3. Verify the target project and click `Add Package` if there are no problems.

## Usage

UniversalSFSymbolsPicker can be implemented as follows.

```swift
import SwiftUI
import UniversalSFSymbolsPicker

struct ContentView: View {
    @State private var isPresented = false
    @State private var selectedIcon: String? = "star.fill"
    @State private var searchText = ""

    var body: some View {
        Button("Show Icon Picker") {
            isPresented = true
        }
        .sheet(isPresented: $isPresented) {
            NavigationStack {
                SFSymbolPicker(
                    isPresented: $isPresented,
                    selection: $selectedIcon,
                    searchText: $searchText
                )
            }
        }
    }
}
```

By default, it is optimized to be displayed as a sheet, and it must be wrapped in a `NavigationStack` so that the toolbar is displayed correctly.

By changing the options, you can display it beautifully even outside of a sheet.

### Display Modes

The symbol picker provided by UniversalSFSymbolsPicker supports the following display modes.

#### Sheet (Default)

![Sheet Mode](docs/images/UniversalSFSymbolsPicker_Sheet_Mode.webp)

By default, it is optimized to be displayed as a sheet as described above, so you can obtain the optimal display without changing any options.

> [!NOTE]
> It cannot be displayed as a sheet on tvOS (for layout and operability reasons).

##### Sample Code

```swift
@State private var isPresented = false
@State private var selectedIcon: String? = "star.fill"
@State private var searchText = ""

var body: some View {
    Button("Show Icon Picker") {
        isPresented = true
    }
    .sheet(isPresented: $isPresented) {
        NavigationStack {
            SFSymbolPicker(
                isPresented: $isPresented,
                selection: $selectedIcon,
                searchText: $searchText
            )
        }
    }
}
```

#### Popover

![Popover Mode](docs/images/UniversalSFSymbolsPicker_Popover_Mode.webp)

By changing the `showAs` option to `.popover`, it becomes optimal for popover display and display other than a sheet.
Since there is no toolbar in popover mode, there is no need to wrap it in a `NavigationStack`.

> [!NOTE]
> It cannot be displayed as a popover on watchOS and tvOS.

> [!IMPORTANT]
> On iOS and iPadOS in a compact size class, placing `.popover` deep in the view hierarchy prevents the scroll edge effect from displaying correctly. Therefore, I recommend attaching `.popover` to a root view only in compact size classes, or using `.sheet` instead on these platforms.

##### Sample Code

```swift
@State private var isPresented = false
@State private var selectedIcon: String? = "star.fill"
@State private var searchText = ""

var body: some View {
    Button("Show Icon Picker") {
        isPresented = true
    }
    .popover(isPresented: $isPresented) {
        SFSymbolPicker(
            isPresented: $isPresented,
            selection: $selectedIcon,
            showAs: .popover,
            searchText: $searchText
        )
    }
}
```

#### NavigationLink

![NavigationLink with Popover Mode](docs/images/UniversalSFSymbolsPicker_NavigationLink_with_Popover_Mode.webp)

On platforms that do not support sheets and popovers, you can achieve a full-screen transition with a beautiful display by implementing it using `NavigationLink` with the `showAs` option changed to `.popover`.
To use `NavigationLink`, the root view containing the symbol picker must be wrapped in a `NavigationStack`.

##### Sample Code

```swift
@State private var selectedIcon: String? = "star.fill"
@State private var searchText = ""

var body: some View {
    NavigationStack {
        Form {
            NavigationLink {
                SFSymbolPicker(
                    isPresented: .constant(true),
                    selection: $selectedIcon,
                    showAs: .popover,
                    searchText: $searchText
                )
                .navigationTitle("Select an Icon")
            } label: {
                HStack {
                    Text("Select Icon")
                    Spacer()
                    Image(systemName: selectedIcon ?? "star.fill")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}
```

### How to use the picker

There are two selection states for icons.\
One is the "provisional selection" state, which represents the state where an icon is highlighted when single-tapped or clicked (except on tvOS). In this state, the selection of the icon is not confirmed, so executing a cancel action (such as clicking the cancel button or swiping down the sheet to close it) will cancel the icon selection (reverting to the icon that was selected before the provisional selection).\
The other is the "main selection" state, which is the icon bound to the `selection` parameter. In the picker, the icon with a border around it is in the main selection state, indicating that it is currently selected. On tvOS, for operational reasons, there is no provisional selection state, and clicking an icon immediately makes it the main selection.

You can select an icon (confirm the selection by making it the main selection) by performing the following actions in the picker:

- Double-tap or click the icon you want to select (except tvOS)
  - Confirming the selection by double-tapping or clicking an icon will automatically close the sheet or popover along with transitioning the icon to the main selection state.
- Execute the completion action (such as pressing the Done button) while in the provisional selection state (except tvOS)
- Close the popover or return to the previous screen while in the provisional selection state
  - On iOS / iPadOS / macOS, it transitions to the main selection at the timing of `.onDisappear` only when the `showAs` option is `.popover`. On watchOS, it always transitions to the main selection regardless of the option.

### Available Options

All available options and default values in UniversalSFSymbolsPicker are as follows. Default values are provided for non-required options, so there is no problem implementing without writing what you do not need to change.

| Parameter Name | Type | Default Value |
| :--- | :--- | :--- |
| [`isPresented`](docs/OPTIONS.md#ispresented) | `Binding<Bool>` | - (Required) |
| [`selection`](docs/OPTIONS.md#selection) | `Binding<String?>` | - (Required) |
| [`showAs`](docs/OPTIONS.md#showas) | `SFSymbolPickerDisplayMode` | `.sheet` |
| [`controlBarPosition`](docs/OPTIONS.md#controlbarposition) | `SFSymbolPickerControlBarPosition` | `.bottom` |
| [`showSearchBar`](docs/OPTIONS.md#showsearchbar) | `Bool` | `true` |
| [`prompt`](docs/OPTIONS.md#prompt) | `String?` | `nil` |
| [`searchText`](docs/OPTIONS.md#searchtext) | `Binding<String>` | `.constant("")` |
| [`showCategoryPicker`](docs/OPTIONS.md#showcategorypicker) | `Bool` | `true` |
| [`showCategorySectionLabel`](docs/OPTIONS.md#showcategorysectionlabel) | `Bool` | `true` |
| [`categoryLabelVisibility`](docs/OPTIONS.md#categorylabelvisibility) | `SFSymbolPickerCategoryLabelVisibility` | `.default` |
| [`categoryLabelStyle`](docs/OPTIONS.md#categorylabelstyle) | `SFSymbolPickerCategoryLabelStyle` | `.both` |
| [`defaultCategory`](docs/OPTIONS.md#defaultcategory) | `String` | `"all"` |
| [`includedCategories`](docs/OPTIONS.md#includedcategories) | `[String]?` | `nil` |
| [`excludedCategories`](docs/OPTIONS.md#excludedcategories) | `[String]?` | `nil` |
| [`customCategories`](docs/OPTIONS.md#customcategories) | `[CustomCategory]` | `[]` |
| [`showIconName`](docs/OPTIONS.md#showiconname) | `Bool` | `true` |
| [`excludeRestricted`](docs/OPTIONS.md#excluderestricted) | `Bool` | `false` |
| [`iconScale`](docs/OPTIONS.md#iconscale) | `Int` | `5` |
| [`iconSpacing`](docs/OPTIONS.md#iconspacing) | `Int` | `5` |
| [`showRecents`](docs/OPTIONS.md#showrecents) | `Bool` | `false` |
| [`maxRecents`](docs/OPTIONS.md#maxrecents) | `Int` | `20` |
| [`renderingMode`](docs/OPTIONS.md#renderingmode) | `SymbolRenderingMode` | `.monochrome` |
| [`isGradient`](docs/OPTIONS.md#isgradient) | `Bool` | `false` |
| [`primaryColor`](docs/OPTIONS.md#primarycolor--secondarycolor--tertiarycolor) | `Color` | `.primary` |
| [`secondaryColor`](docs/OPTIONS.md#primarycolor--secondarycolor--tertiarycolor) | `Color?` | `nil` |
| [`tertiaryColor`](docs/OPTIONS.md#primarycolor--secondarycolor--tertiarycolor) | `Color?` | `nil` |
| [`variableValue`](docs/OPTIONS.md#variablevalue) | `Binding<Double?>` | `.constant(nil)` |
| [`sfSymbolsVersion`](docs/OPTIONS.md#sfsymbolsversion) | `Double?` | `nil` |

For more detailed information on differences and how to use all options, please see the [Options Documentation page](docs/OPTIONS.md).

## UniversalSFSymbolsPicker Demo

![UniversalSFSymbolsPicker Demo](docs/images/UniversalSFSymbolsPicker_Demo.webp)

A useful demo app to check the actual behavior when implementing UniversalSFSymbolsPicker in your own app is included in [`Examples/USSPDemo`](Examples/USSPDemo).
This demo app works on all platforms supported by the package, so you can build it on a simulator or your own device to check the behavior.

In the UniversalSFSymbolsPicker Demo, you can try out most of the options provided by UniversalSFSymbolsPicker, making it perfect for thoroughly testing the differences in behavior across platforms and the differences between options.

### Build Mode

![Build Mode](docs/images/UniversalSFSymbolsPicker_Build_Mode.webp)

By clicking the "Open Build Mode" button at the very bottom of the UniversalSFSymbolsPicker Demo, you can open the Build Mode which generates code that is useful when implementing UniversalSFSymbolsPicker.
You can check the behavior of the picker while changing options, and once you have decided on the options you want to implement, you can copy the ready-to-use code, which is helpful when integrating UniversalSFSymbolsPicker into your app.

Build Mode is available on iOS / iPadOS / macOS / visionOS. It is not implemented on watchOS and tvOS due to considerations such as display area and operability (the regular demo is available).

## Credits

UniversalSFSymbolsPicker was developed drawing inspiration from the following wonderful projects:

- [**SFSymbolsPicker by jaywcjlove**](https://github.com/jaywcjlove/SFSymbolsPicker)
- [**SymbolPicker by xnth97**](https://github.com/xnth97/SymbolPicker)

Additionally, the following tool was used in the development of UniversalSFSymbolsPicker:

- [**Antigravity IDE by Google**](https://antigravity.google/)
