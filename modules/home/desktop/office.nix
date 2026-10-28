{
  config,
  lib,
  pkgs,
  ...
}:

let
  profile = "${config.xdg.configHome}/libreoffice/4/user/registrymodifications.xcu";

  item =
    path: prop: value:
    ''<item oor:path="${path}"><prop oor:name="${prop}" oor:op="fuse"><value>${value}</value></prop></item>'';
  factory =
    doc: "/org.openoffice.Setup/Office/Factories/org.openoffice.Setup:Factory['com.sun.star.${doc}']";
  toolbarMode =
    app:
    "/org.openoffice.Office.UI.ToolbarMode/Applications/org.openoffice.Office.UI.ToolbarMode:Application['${app}']";

  # Starting preferences that make LibreOffice behave like MS Office.
  msDefaults = pkgs.writeText "registrymodifications.xcu" ''
    <?xml version="1.0" encoding="UTF-8"?>
    <oor:items xmlns:oor="http://openoffice.org/2001/registry" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
    ${item (factory "text.TextDocument") "ooSetupFactoryDefaultFilter" "MS Word 2007 XML"}
    ${item (factory "sheet.SpreadsheetDocument") "ooSetupFactoryDefaultFilter" "Calc MS Excel 2007 XML"}
    ${item (factory "presentation.PresentationDocument") "ooSetupFactoryDefaultFilter"
      "Impress MS PowerPoint 2007 XML"
    }
    ${item "/org.openoffice.Office.Common/Save/Document" "WarnAlienFormat" "false"}
    ${item (toolbarMode "Writer") "Active" "notebookbar.ui"}
    ${item (toolbarMode "Calc") "Active" "notebookbar.ui"}
    ${item (toolbarMode "Impress") "Active" "notebookbar.ui"}
    ${item (toolbarMode "Draw") "Active" "notebookbar.ui"}
    ${item "/org.openoffice.Office.Common/Misc" "SymbolStyle" "colibre"}
    ${item "/org.openoffice.Office.Writer/DefaultFont" "Standard" "Carlito"}
    </oor:items>
  '';
in
{
  home.packages = with pkgs;
  [
    libreoffice
    hunspell
    hunspellDicts.en_GB-ise
    hunspellDicts.hu_HU
  ];

  # LibreOffice rewrites this file whenever a setting changes, so it can't be
  # a read-only store link. Seed it once; later changes made in the app stick.
  # Delete the file to go back to these defaults.
  home.activation.libreofficeDefaults = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ ! -e "${profile}" ]; then
      run mkdir -p "$(dirname "${profile}")"
      run install -m 644 ${msDefaults} "${profile}"
    fi
  '';
}
