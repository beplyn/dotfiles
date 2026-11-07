{ config, pkgs, ... }:

let
  p = config.themes.palette;

  # glamour style built from the palette; stylix has no glow target
  style =
  {
    document =
    {
      block_prefix = "\n";
      block_suffix = "\n";
      color = p.foreground;
      margin = 2;
    };
    block_quote =
    {
      color = p.subtext;
      italic = true;
      indent = 1;
      indent_token = "│ ";
    };
    paragraph = { };
    list =
    {
      level_indent = 2;
    };
    heading =
    {
      block_suffix = "\n";
      color = p.accent;
      bold = true;
    };
    h1 =
    {
      prefix = " ";
      suffix = " ";
      color = p.background;
      background_color = p.accent;
      bold = true;
    };
    h2 =
    {
      prefix = "## ";
    };
    h3 =
    {
      prefix = "### ";
      color = p.blue;
    };
    h4 =
    {
      prefix = "#### ";
      color = p.cyan;
    };
    h5 =
    {
      prefix = "##### ";
      color = p.green;
    };
    h6 =
    {
      prefix = "###### ";
      color = p.muted;
      bold = false;
    };
    text = { };
    strikethrough.crossed_out = true;
    emph.italic = true;
    strong.bold = true;
    hr =
    {
      color = p.muted;
      format = "\n--------\n";
    };
    item.block_prefix = "• ";
    enumeration.block_prefix = ". ";
    task =
    {
      ticked = "[✓] ";
      unticked = "[ ] ";
    };
    link =
    {
      color = p.blue;
      underline = true;
    };
    link_text =
    {
      color = p.cyan;
      bold = true;
    };
    image =
    {
      color = p.blue;
      underline = true;
    };
    image_text =
    {
      color = p.muted;
      format = "Image: {{.text}} →";
    };
    code =
    {
      prefix = " ";
      suffix = " ";
      color = p.orange;
      background_color = p.surface;
    };
    code_block =
    {
      color = p.foreground;
      margin = 2;
      chroma =
      {
        text.color = p.foreground;
        error =
        {
          color = p.background;
          background_color = p.error;
        };
        comment =
        {
          color = p.muted;
          italic = true;
        };
        comment_preproc.color = p.orange;
        keyword.color = p.purple;
        keyword_reserved.color = p.purple;
        keyword_namespace.color = p.purple;
        keyword_type.color = p.yellow;
        operator.color = p.cyan;
        punctuation.color = p.subtext;
        name.color = p.foreground;
        name_builtin.color = p.red;
        name_tag.color = p.red;
        name_attribute.color = p.yellow;
        name_class =
        {
          color = p.yellow;
          bold = true;
        };
        name_constant.color = p.orange;
        name_decorator.color = p.cyan;
        name_exception.color = p.red;
        name_function.color = p.blue;
        name_other.color = p.foreground;
        literal.color = p.orange;
        literal_number.color = p.orange;
        literal_date.color = p.orange;
        literal_string.color = p.green;
        literal_string_escape.color = p.cyan;
        generic_deleted.color = p.red;
        generic_emph.italic = true;
        generic_inserted.color = p.green;
        generic_strong.bold = true;
        generic_subheading.color = p.muted;
        background.background_color = p.mantle;
      };
    };
    table = { };
    definition_list = { };
    definition_term = { };
    definition_description.block_prefix = "\n🠶 ";
    html_block = { };
    html_span = { };
  };
in

{
  home.packages = [ pkgs.glow ];

  xdg.configFile."glow/stylix.json".text = builtins.toJSON style;
  xdg.configFile."glow/glow.yml".text = ''
    style: "${config.xdg.configHome}/glow/stylix.json"
    mouse: true
    width: 100
  '';
}
