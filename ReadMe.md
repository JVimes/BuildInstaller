# BuildInstaller

BuildInstaller is a NuGet package that causes a Visual Studio project to produce an installer during Release builds (configurable).

The project's build output files will be installed under "Program Files (x86)" and a shortcut placed at the root of Start menu. The application can be uninstalled via Apps & Features.

# Use

Install the BuildInstaller package in your application project. On Release builds, the installer will appear in:

- `bin\Release\<TargetFramework>-installer`
- For old .csproj format: `bin\Release-installer`

## Version Numbers and Upgrades

For new installers to upgrade old ones, increment any of the first _three_ digit-groups in your .exe's assembly version, e.g. `1.0.21.0` to `1.0.22.0`. Windows Installer does not check the fourth digit-group and will otherwise install duplicate entries in Apps & Features. You can delete the fourth group.

## Defaults

Certain Windows Installer properties are set from project properties. For .NET projects, see the Package tab. For the old .csproj format, click the Assembly Information button.

| Project                                | Windows Installer               |
|----------------------------------------|---------------------------------|
| Package Version<br>(Assembly Version)  | ProductVersion                  |
| Product                                | ProductName                     |
| Company<br>(if empty, Product)         | Manufacturer<br>(aka Publisher) |

## Customization

Some things can be customized via the .csproj or Product.wxs files.

### Icon

To have a program icon, see the comment in [ProjectFolder]\Installer\Product.wxs, which appears on first installer build.

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

- **BuildInstallerOnPublish** - Set this to `true` to build an installer on Publish instead of Build (only works on "folder" type publish).
    - Example: `true`

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
        - This is all files below the output/publish folder.

- **InstallerSourceFiles** - The installer source code files. If they are in the same folder, use the InstallerSourceFolder property instead.
    - Default: `$(InstallerSourceFolder)\**\*.wxs;$(FilesFragmentWxs)`
        - This is all .wxs files below the project's `Install` folder, and a "fragment" file (created by the build) that references the files to install.

### Installer Source Code

The installer is built using [The WiX Toolset][WiXUrl]. The installer can be customized by editing [ProjectFolder]\Installer\Product.wxs, which appears on first installer build, or by adding other WiX source code files to the same folder.

# Developing BuildInstaller

The **BuildInstaller project** builds the NuGet package and deletes local caches of it. 

Its PackageFiles subfolder holds MSBuild files that will be part of projects that use the package. The primary file is BuildInstaller.targets, which has entry points `BuildInstallerIfShould` and `CleanInstallerFolders`.

The **TestApp projects** install the package directly from where it was built due to the local NuGet.config file. Switch which line in that file is commented when switching between Debug and Release modes:

```xml
<add key="BuildInstallerDebugFolder" value="BuildInstaller\bin\Debug\" />
<!--<add key="BuildInstallerReleaseFolder" value="BuildInstaller\bin\Release\" />-->
```

## Testing

- For TestApp and TestAppOldProjFormat (recommend testing one at a time), make sure these work right:
    - Clean
    - Build
    - Rebuild
    - Folder Publish, only for TestApp, needs BuildInstallerOnPublish set to `true`.
    - ClickOnce Publish does *not* cause an installer build.

- Make sure the installer is only built for configurations listed in the InstallerBuildConfigurations property.

- Edit the application's "Product" and "Company" properties (see "Package" or "Assembly Information" settings) and do a Build. Make sure:
    - A build happens ("up-to-date" doesn't show for the project in the build output)
    - The new values show when installed. Check in the "Programs and Features" window from Control Panel.

- Edit a product source code file in a way that shows at runtime and make sure the change shows up in the installed product.

- Make sure that building the app a second time in a row shows "up-to-date" in the build output, and nothing is built the second time. Note: Before testing this, build the BuildInstaller project and then unload it (otherwise the second build happens, regardless).

- Test command-line builds
  - Using "Developer PowerShell for VS", `msbuild -restore` should build the solution.
  - The dotnet CLI doesn't seem to work for TestAppOldProjFormat, but build the others:  
    `dotnet build .\BuildInstaller\BuildInstaller.csproj`  
    `dotnet build .\TestApp\TestApp.csproj`


[WiXUrl]: https://wixtoolset.org/documentation/manual/v3/main/
[MSBuildItems]: https://docs.microsoft.com/en-us/visualstudio/msbuild/msbuild-items
[MSBuildProperties]: https://docs.microsoft.com/en-us/visualstudio/msbuild/msbuild-properties
[Any2Ico]: https://www.carifred.com/quick_any2ico/