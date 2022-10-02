# BuildInstaller

BuildInstaller is a NuGet package that causes a Visual Studio project to produce an installer during Release builds (configurable).

The project's output files will be installed under Program Files and a shortcut placed at the root of Start menu. The application can be uninstalled via Apps & Features.

# Use

Install the BuildInstaller package in your application's project. On Release builds the installer will appear in:

- `bin\Release\<TargetFramework>-installer`
- For old .csproj format: `bin\Release-installer`

## Version Numbers and Upgrades

For new installers to upgrade old ones, increment any of the first _three_ digit-groups in your .exe's assembly version, e.g. `1.0.21.0` to `1.0.22.0`. Windows Installer does not check the fourth digit-group and will otherwise install duplicate entries in Apps & Features. You can delete the fourth digit group.

## License Agreement File

The install-time license agreement text is set from [Project]\Installer\License.rtf, which is created on first installer build. Edit it with WordPad.

## Defaults

Project properties are used to set certain Windows Installer properties. For .NET projects, see the Package tab. But for the old .csproj format, click the Assembly Information button.

| Project                            | Windows Installer            |
|------------------------------------|------------------------------|
| Package Version (Assembly Version) | ProductVersion               |
| Product                            | ProductName                  |
| Company (if empty, Product)        | Manufacturer (aka Publisher) |

## Customization

Some things can be customized via the .csproj or Product.wxs files.

### Icon

To have a program icon, see the comment in [Project]\Installer\Product.wxs, which is created on first installer build.

An easy way to create an icon file is to convert a 256x256 .png image using [Quick Any2Ico][Any2Ico], which has a free edition.

### Properties

Some MSBuild [properties][MSBuildProperties] can be overridden in the .csproj:

```
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

- **InstallerArchitecture** - Selects between "Program Files" and "Program Files (x86)" install folders, and certain registry paths if set via WiX. Set to either x86, x64, or ia64.
  - Default: `x64`
  - Example: `x86`

- **InstallerOutputPath** - Path where the installer will be built to.
    - Default: `$(ProductFolderParent)\$(ProductFolderName)-installer`

- **ProductFolder** - Path containing files to install, relative to the project. If the files are in various folders, use the ProductFiles item instead.
    - Default: `$(OutputPath)` or `$(PublishDir)`

- **InstallerSourceFolder** - Path containing installer source code, relative to the project. If the files are in various folders, use the InstallerSourceFiles item instead.
    - Default: `Installer`

### Build Items

Some MSBuild [items][MSBuildItems] can be overridden in the .csproj:

```
<ItemGroup>
    <TheItemName Include="path\relative\to\project\**\*.*;another\path\*.txt"
                 Exclude="*.foo"/>
</ItemGroup>
```

These items are:

- **ProductFiles** - The files to install. If they are in the same folder, use the ProductFolder property instead.
    - Default: `$(ProductFolder)\**\*.*`  
        (all files below the output/publish folder)

- **InstallerSourceFiles** - The installer source code files. If they are in the same folder, use the InstallerSourceFolder property instead.
    - Default: `$(InstallerSourceFolder)\**\*.wxs;$(FilesFragmentWxs)`  
        (all .wxs files below the project's `Install` folder and a "fragment" file created by the build that references the files to install)

### Installer Source Code

The installer is built using [The WiX Toolset][WiXUrl]. The installer can be customized by editing [Project]\Installer\Product.wxs (which is created on first installer build) or by adding other WiX source code files to the same folder.

# Developing BuildInstaller

There are sometimes errors the first time this solution is built and they go away on subsequent build. Maybe NuGet restore runs too late the first time.

The **BuildInstaller project** builds the NuGet package and deletes local caches of it.
  - Its PackageFiles folder holds MSBuild files that run in projects that use BuildInstaller.
  - The primary file is BuildInstaller.targets, which has entry points `BuildInstallerIfShould` and `CleanInstallerFolders`.

The **"test app" projects** consume the BuildInstaller NuGet package. They do so directly from where it was built (due to the local NuGet.config).

## Testing

Manually test the BuildInstaller NuGet package via TestApp and TestAppOldProjFormat. Recommend building the BuildInstaller project, unloading it, then testing each app in isolation by first unloading the other.

Make sure:

- The build actions work correctly: Build, Rebuild, Clean.
- The installer is only built for build configurations listed in the InstallerBuildConfigurations property.
- Building the app a second time in a row causes "up-to-date" to show in Output. Before testing this, unload the BuildInstaller project because it artificially forces the second build.
- InstallerArchitecture correctly affects install location: "Program Files" vs "Program Files (x86)".
- Try the 'To remove the "done" dialog' instructions in SimpleUI.wxs.

Edit the application's "Product" and "Company" properties (see "Package" or "Assembly Information" project settings, depending on project format), do a Build, and make sure:

- A build happens ("up-to-date" doesn't appear for the project in Output)
- The new values are used by the installer. Look in "Programs and Features" from Control Panel to see both values.

Edit a test app source code file in a way that shows at runtime and make sure the change shows up in the installed product.  
- Test upgrading a previous installation (see [Version Numbers and Upgrades](#version-numbers-and-upgrades)). Make test app changes in the new version to show the upgrade actually works.

Test command-line builds by opening Developer PowerShell for VS and making sure:
  - MSBuild can build the whole solution: `msbuild -restore`
  - The dotnet CLI can build the following:
    - `dotnet build .\BuildInstaller\BuildInstaller.csproj`
    - `dotnet build .\TestApp\TestApp.csproj`
    - (it can't handle TestAppOldProjFormat)


[WiXUrl]: https://wixtoolset.org/documentation/manual/v3/main/
[MSBuildItems]: https://docs.microsoft.com/en-us/visualstudio/msbuild/msbuild-items
[MSBuildProperties]: https://docs.microsoft.com/en-us/visualstudio/msbuild/msbuild-properties
[Any2Ico]: https://www.carifred.com/quick_any2ico/