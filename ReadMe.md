# BuildInstaller

BuildInstaller is a NuGet package that causes a Visual Studio project to produce an installer during Release builds (configurable). It has been tested with .NET projects and might need changes to support other types. The installer is a .msi file (Windows Installer package).

The project's output files will be installed under Program Files and an application shortcut placed at the root of Start menu. Running the installer again gives access to the Remove and Repair buttons. The application can also be uninstalled via Apps & Features.

# Use

Install the BuildInstaller package in your application's project. On Release builds the installer will appear in:

- `bin\Release\<TargetFramework>-installer`
- For old .csproj format: `bin\Release-installer`

## Version Numbers and Upgrades

For new installers to upgrade old ones, increment any of the first _three_ digit-groups in your .exe's assembly version, e.g. `1.0.21.0` to `1.0.22.0`. Windows Installer does not check the fourth digit-group and will otherwise install duplicate entries in Apps & Features. You can delete the fourth digit group.

The version number is read from the applications package version aka the .csproj `version` property. For the old .csproj format, you have to add a `<version>` property to the .csproj.

## License Agreement File

The install-time license agreement text is set from [Project]\Installer\License.rtf, which is created on first installer build. Edit it with WordPad.

## Defaults

Project properties are used to set certain Windows Installer properties. For .NET projects, see the Package tab. But for the old .csproj format, click the Assembly Information button.

| Project                     | Windows Installer            |
|-----------------------------|------------------------------|
| Package Version             | ProductVersion               |
| Product                     | ProductName                  |
| Company (if empty, Product) | Manufacturer (aka Publisher) |

## Customization

Some things can be customized via the .csproj or .wxs files.

### Icon

To have a program icon, see the comment in [Project]\Installer\Product.wxs, which is created on first installer build.

An easy way to create an icon file is to convert a 256x256 .png image using [Quick Any2Ico][Any2Ico] free edition.

### Properties

Some MSBuild [properties][MSBuildProperties] can be overridden in the .csproj:

```xml
<PropertyGroup>
    <ThePropertyName>YourCustomValue</ThePropertyName>
</PropertyGroup>
```

These properties are:

- **InstallerName** - The name of the installer file (without file extension).
    - Default: `$(Product)_$(Version)_$(TargetFramework)`  
      - For old .csproj format: `$(Product)_$(Version)`
    - Example: `Foo-$(Version)`

- **InstallerBuildConfigurations** - Semicolon separated list of build configurations, for each of which an installer will build.
    - Default: `Release`
    - Example: `Debug;Release`

- **InstallerArchitecture** - Selects between "Program Files" and "Program Files (x86)" install folders (and affects registry paths set via [installer source code](#installer-source-code)). Set to either x86, x64, or ia64.
  - Default: `x64`
  - Example: `x86`

- **InstallerOutputPath** - Path where the installer will be built to.
    - Default: `$(ProductFolderParent)\$(ProductFolderName)-installer`

- **ProductFolder** - Folder path containing files to install (relative to the project). If the files are in various folders then use the ProductFiles item instead.
    - Default: `$(OutputPath)` or `$(PublishDir)`

- **InstallerSourceFolder** - Path containing installer source code (relative to the project). If the files are in various folders then use the InstallerSourceFiles item instead.
    - Default: `Installer`

### Build Items

Some MSBuild [items][MSBuildItems] can be overridden in the .csproj:

```xml
<ItemGroup>
    <TheItemName Include="path\relative\to\project\**\*.*;another\path\*.txt"
                 Exclude="*.foo"/>
</ItemGroup>
```

These items are:

- **ProductFiles** - The files to install. If they are in a folder together then use the ProductFolder property instead.
    - Default: `$(ProductFolder)\**\*.*`  
        (all files below the output/publish folder)

- **InstallerSourceFiles** - The installer source code files. If they are in a folder together then use the InstallerSourceFolder property instead.
    - Default: `$(InstallerSourceFolder)\**\*.wxs;$(FilesFragmentWxs)`  
        (all .wxs files below the project's `Install` folder and a "fragment" file created by the build that references the files to install)

### Installer Source Code

The installer is built using [The WiX Toolset][WiXUrl]. The installer can be customized by editing Product.wxs and SimpleUI.wxs which are created in [Project]\Installer\ on first installer build, or by adding other WiX source code files to that folder.

# Developing BuildInstaller

There are sometimes errors the first time the solution or TestApp.OldProjFormat are built. The errors seem to go away if build is run a second time (something to do with NuGet restore?).

The **BuildInstaller project** builds the NuGet package and deletes local caches of it.
  - Its PackageFiles folder holds MSBuild files that run in projects that use BuildInstaller.
  - The primary file is BuildInstaller.targets, which has entry points `BuildInstallerIfShould` and `CleanInstallerFolders`.

The **"test app" projects** consume the BuildInstaller NuGet package. They do so directly from where it was built due to the local NuGet.config.

## Testing

Manually test the BuildInstaller NuGet package via TestApp and TestApp.OldProjFormat. Recommend building the BuildInstaller project, unloading it, then testing each app in isolation by first unloading the other.

Make sure:

- The build actions work correctly: Build, Rebuild, Clean.
- The installer is only built for build configurations listed in the InstallerBuildConfigurations property.
- Building the app a second time in a row causes "up-to-date" to show in Output. Before testing this, unload the BuildInstaller project because it artificially forces the second build.
- InstallerArchitecture correctly affects install location: "Program Files" vs "Program Files (x86)".
- Try the 'To remove the "done" dialog' instructions in SimpleUI.wxs.

Edit the application's "Product" and "Company" properties (see "Package" or "Assembly Information" project settings, depending on project format), do a Build, and make sure:

- A build happens ("up-to-date" doesn't appear for the project in Output)
- The new values are used by the installer. Look in "Programs and Features" from Control Panel to see both values.

Test upgrading a previous installation (see [Version Numbers and Upgrades](#version-numbers-and-upgrades)). Make changes to the test app visible at runtime to show the upgrade worked.

Test command-line builds by opening Developer PowerShell for VS and making sure:
  - MSBuild can build the whole solution: `msbuild -restore`
  - The dotnet CLI can build the following:
    - `dotnet build .\BuildInstaller\BuildInstaller.csproj`
    - `dotnet build .\TestApp\TestApp.csproj`
    - (it can't handle TestApp.OldProjFormat)


[WiXUrl]: https://wixtoolset.org/documentation/manual/v3/main/
[MSBuildItems]: https://docs.microsoft.com/en-us/visualstudio/msbuild/msbuild-items
[MSBuildProperties]: https://docs.microsoft.com/en-us/visualstudio/msbuild/msbuild-properties
[Any2Ico]: https://www.carifred.com/quick_any2ico/