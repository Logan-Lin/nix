{ config, pkgs, ... }:

{
  # Install LibreOffice with Java support
  home.packages = with pkgs; [
    libreoffice-fresh
    jre  # Java Runtime Environment for LibreOffice features
  ];

  # Workaround for LibreOffice dark mode on NixOS (Issue #310578)
  # LibreOffice ignores GTK dark theme due to GTK3 bug, so we force it via environment variable
  # These custom desktop entries override the default ones with GTK_THEME=Adwaita:dark

  # LibreOffice Start Center
  home.file.".local/share/applications/libreoffice-startcenter.desktop".text = ''
    [Desktop Entry]
    Version=1.0
    Type=Application
    Name=LibreOffice
    GenericName=Office Suite
    Comment=The office productivity suite compatible to the open and standardized ODF document format. Supported by The Document Foundation.
    Exec=env GTK_THEME=Adwaita:dark libreoffice %U
    Icon=libreoffice-startcenter
    Terminal=false
    Categories=Office;X-Red-Hat-Base;X-SuSE-Core-Office;
    MimeType=application/vnd.openofficeorg.extension;
    StartupNotify=true
  '';

  # LibreOffice Writer
  home.file.".local/share/applications/libreoffice-writer.desktop".text = ''
    [Desktop Entry]
    Version=1.0
    Type=Application
    Name=LibreOffice Writer
    GenericName=Word Processor
    Comment=Create and edit text documents
    Exec=env GTK_THEME=Adwaita:dark libreoffice --writer %U
    Icon=libreoffice-writer
    Terminal=false
    Categories=Office;WordProcessor;X-Red-Hat-Base;X-SuSE-Core-Office;
    MimeType=application/vnd.oasis.opendocument.text;application/vnd.oasis.opendocument.text-template;application/vnd.oasis.opendocument.text-web;application/vnd.oasis.opendocument.text-master;application/vnd.oasis.opendocument.text-master-template;application/vnd.sun.xml.writer;application/vnd.sun.xml.writer.template;application/vnd.sun.xml.writer.global;application/msword;application/vnd.ms-word;application/x-doc;application/x-hwp;application/rtf;text/rtf;application/vnd.wordperfect;application/wordperfect;application/vnd.lotus-wordpro;application/vnd.openxmlformats-officedocument.wordprocessingml.document;application/vnd.ms-word.document.macroEnabled.12;application/vnd.openxmlformats-officedocument.wordprocessingml.template;application/vnd.ms-word.template.macroEnabled.12;application/vnd.ms-works;application/vnd.apple.pages;application/x-iwork-pages-sffpages;application/clarisworks;
    StartupNotify=true
  '';

  # LibreOffice Calc
  home.file.".local/share/applications/libreoffice-calc.desktop".text = ''
    [Desktop Entry]
    Version=1.0
    Type=Application
    Name=LibreOffice Calc
    GenericName=Spreadsheet
    Comment=Perform calculations, analyze information and manage lists in spreadsheets
    Exec=env GTK_THEME=Adwaita:dark libreoffice --calc %U
    Icon=libreoffice-calc
    Terminal=false
    Categories=Office;Spreadsheet;X-Red-Hat-Base;X-SuSE-Core-Office;
    MimeType=application/vnd.oasis.opendocument.spreadsheet;application/vnd.oasis.opendocument.spreadsheet-template;application/vnd.sun.xml.calc;application/vnd.sun.xml.calc.template;application/msexcel;application/vnd.ms-excel;application/vnd.openxmlformats-officedocument.spreadsheetml.sheet;application/vnd.ms-excel.sheet.macroEnabled.12;application/vnd.openxmlformats-officedocument.spreadsheetml.template;application/vnd.ms-excel.template.macroEnabled.12;application/vnd.lotus-1-2-3;application/vnd.apple.numbers;application/x-iwork-numbers-sffnumbers;text/csv;text/spreadsheet;application/csv;application/x-csv;text/comma-separated-values;text/tab-separated-values;application/x-dos_ms_excel;application/x-excel;application/x-msexcel;application/x-ms-excel;application/x-quattropro;application/x-123;text/html;
    StartupNotify=true
  '';

  # LibreOffice Impress
  home.file.".local/share/applications/libreoffice-impress.desktop".text = ''
    [Desktop Entry]
    Version=1.0
    Type=Application
    Name=LibreOffice Impress
    GenericName=Presentation
    Comment=Create and edit presentations for slideshows, meeting and Web pages
    Exec=env GTK_THEME=Adwaita:dark libreoffice --impress %U
    Icon=libreoffice-impress
    Terminal=false
    Categories=Office;Presentation;X-Red-Hat-Base;X-SuSE-Core-Office;
    MimeType=application/vnd.oasis.opendocument.presentation;application/vnd.oasis.opendocument.presentation-template;application/vnd.sun.xml.impress;application/vnd.sun.xml.impress.template;application/mspowerpoint;application/vnd.ms-powerpoint;application/vnd.openxmlformats-officedocument.presentationml.presentation;application/vnd.ms-powerpoint.presentation.macroEnabled.12;application/vnd.openxmlformats-officedocument.presentationml.template;application/vnd.ms-powerpoint.template.macroEnabled.12;application/vnd.openxmlformats-officedocument.presentationml.slide;application/vnd.openxmlformats-officedocument.presentationml.slideshow;application/vnd.ms-powerpoint.slideshow.macroEnabled.12;application/vnd.apple.keynote;application/x-iwork-keynote-sffkey;
    StartupNotify=true
  '';

  # LibreOffice Draw
  home.file.".local/share/applications/libreoffice-draw.desktop".text = ''
    [Desktop Entry]
    Version=1.0
    Type=Application
    Name=LibreOffice Draw
    GenericName=Drawing Program
    Comment=Create and edit drawings, flow charts and logos
    Exec=env GTK_THEME=Adwaita:dark libreoffice --draw %U
    Icon=libreoffice-draw
    Terminal=false
    Categories=Office;FlowChart;Graphics;2DGraphics;VectorGraphics;X-Red-Hat-Base;X-SuSE-Core-Office;
    MimeType=application/vnd.oasis.opendocument.graphics;application/vnd.oasis.opendocument.graphics-template;application/vnd.sun.xml.draw;application/vnd.sun.xml.draw.template;application/vnd.visio;application/x-wpg;
    StartupNotify=true
  '';
}
