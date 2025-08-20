{ config, pkgs, ... }:
let
  jetbrainsNerd =
    if pkgs ? nerd-fonts then pkgs.nerd-fonts.jetbrains-mono else pkgs.nerdfonts;
in
{
  fonts.fontconfig.enable = true;

  home.packages = [
    pkgs.foot
    jetbrainsNerd
  ];

  programs.fish.enable = true;

  programs.kitty = {
    enable = true;
    font = {
      name = "JetBrains Mono Nerd Font";
      size = 11.0;
    };
    extraConfig = ''
      cursor_shape beam
      cursor_trail 1
      window_margin_width 21.75
      confirm_os_window_close 0
      shell fish

      map ctrl+c copy_or_interrupt

      map ctrl+f launch --location=hsplit --allow-remote-control kitty +kitten search.py @active-kitty-window-id
      map kitty_mod+f launch --location=hsplit --allow-remote-control kitty +kitten search.py @active-kitty-window-id

      map page_up scroll_page_up
      map page_down scroll_page_down

      map ctrl+plus change_font_size all +1
      map ctrl+equal change_font_size all +1
      map ctrl+kp_add change_font_size all +1
      map ctrl+minus change_font_size all -1
      map ctrl+underscore change_font_size all -1
      map ctrl+kp_subtract change_font_size all -1
      map ctrl+0 change_font_size all 0
      map ctrl+kp_0 change_font_size all 0
    '';
  };

  xdg.configFile."foot/foot.ini".text = ''
    shell=fish
    term=xterm-256color

    title=foot

    font=JetBrainsMono Nerd Font:size=11
    letter-spacing=0
    dpi-aware=no

    pad=25x25

    bold-text-in-bright=no

    [scrollback]
    lines=10000

    [cursor]
    style=beam
    blink=no
    beam-thickness=1.5

    [key-bindings]
    scrollback-up-page=Page_Up
    scrollback-down-page=Page_Down
    clipboard-copy=Control+c
    clipboard-paste=Control+v
    search-start=Control+f
    font-increase=Control+plus Control+equal Control+KP_Add
    font-decrease=Control+minus Control+KP_Subtract
    font-reset=Control+0 Control+KP_0

    [search-bindings]
    cancel=Escape
    find-prev=Shift+F3
    find-next=F3 Control+G
    delete-prev-word=Control+BackSpace

    [text-bindings]
    \x03=Control+Shift+c
  '';
}
