{
  ...
}:

{
  programs.equibop.equicord.settings.plugins = {
    AudioPlayerAPI.enabled = true;
    BadgeAPI.enabled = true;
    ChatInputButtonAPI.enabled = true;
    CommandsAPI.enabled = true;
    ContextMenuAPI.enabled = true;
    DynamicImageModalAPI.enabled = true;
    ExtraContextMenusAPI.enabled = true;
    HeaderBarAPI.enabled = true;
    MemberListDecoratorsAPI.enabled = true;
    MessageAccessoriesAPI.enabled = true;
    MessageDecorationsAPI.enabled = true;
    MessageEventsAPI.enabled = true;
    MessagePopoverAPI.enabled = true;
    MessageUpdaterAPI.enabled = true;
    NicknameIconsAPI.enabled = true;
    NoticesAPI.enabled = true;
    ProfileCollectionsAPI.enabled = true;
    ProfileSectionsAPI.enabled = true;
    ServerListAPI.enabled = true;
    SurfaceClassesAPI.enabled = true;
    UserAreaAPI.enabled = true;
    UserSettingsAPI.enabled = true;

    AccountPanelServerProfile = {
      enabled = true;
      prioritizeServerProfile = false;
    };
    AddAttachments.enabled = true;
    AdvancedPermissions = {
      enabled = true;
      simplifiedCard = "hide";
    };
    AnonymiseFileNames = {
      enabled = true;
      anonymiseByDefault = true;
      consistent = "image";
      dateFormat = "YYYY-MM-DD_HH-mm-ss-SSS";
      method = 2;
      randomisedLength = 7;
      spoilerMessages = false;
    };
    AutoZipper = {
      enabled = true;
      extensions = ".psd,.blend,.exe,.dmg,.app,.apk,.iso";
    };
    BetterBlockedUsers.enabled = true;
    BetterForwards = {
      enabled = true;
      dontFollowForwards = false;
      resendOnFail = true;
      selfForward = false;
    };
    BetterGifLoad = {
      enabled = true;
      gifQuality = 1;
    };
    BetterGifPicker = {
      enabled = true;
      keepOpen = false;
    };
    BetterInvites.enabled = true;
    BetterRoleContext.enabled = true;
    BetterSettings = {
      enabled = true;
      disableFade = true;
      eagerLoad = true;
      organizeMenu = true;
    };
    BiggerStreamPreview.enabled = true;
    BlockKrisp.enabled = true;
    BypassPinPrompt.enabled = true;
    CallTimer = {
      enabled = true;
      allCallTimers = false;
      format = "stopwatch";
      watchLargeGuilds = false;
    };
    ChannelBadges = {
      enabled = true;
      announcementBadgeLabel = "News";
      forumBadgeLabel = "Forum";
      mediaBadgeLabel = "Media";
      nsfwBadgeLabel = "NSFW";
      oneBadgePerChannel = false;
      rulesBadgeLabel = "Rules";
      showAnnouncementBadge = true;
      showForumBadge = true;
      showMediaBadge = true;
      showNSFWBadge = true;
      showRulesBadge = true;
      showStageBadge = true;
      showTextBadge = true;
      showVoiceBadge = true;
      stageBadgeLabel = "Stage";
      textBadgeLabel = "Text";
      voiceBadgeLabel = "Voice";
    };
    CharacterCounter = {
      enabled = true;
      colorEffects = true;
    };
    CleanerChannelGroups.enabled = true;
    ColorSighted.enabled = true;
    ConcatenatedComponentExtractor.enabled = true;
    CrashHandler = {
      enabled = true;
      attemptToNavigateToHome = false;
      attemptToPreventCrashes = true;
    };
    DisableDeepLinks.enabled = true;
    EquicordHelper = {
      enabled = true;
      accountStandingButton = false;
      disableAdoptTagPrompt = false;
      enableAutoCorrect = false;
      forceRoleIcon = false;
      hideVoiceIndicatorForMutedChannels = false;
      jsonGateway = false;
      noBulletPoints = false;
      noModalAnimation = false;
      noOnboarding = false;
      noMirroredCamera = false;
      refreshSlashCommands = false;
      removeActivitySection = false;
      restoreFileDownloadButton = false;
      showYourOwnActivityButtons = false;
    };
    FixSpotifyEmbeds = {
      enabled = true;
      volume = 10;
    };
    ForceOwnerCrown.enabled = true;
    FriendsSince.enabled = true;
    GameActivityToggle = {
      enabled = true;
      location = "PANEL";
      oldIcon = false;
    };
    GifMaker = {
      enabled = true;
      lastBubbleTipBase = 0.1;
      lastCaptionMode = "none";
      lastCaptionSize = 40;
      lastCaptionText = "";
      lastFontFamily = "Arial";
      lastHeight = 256;
      lastWidth = 256;
      maxHeight = 720;
      maxWidth = 1280;
    };
    GifProviderSwitcher = {
      enabled = true;
      provider = [
        "tenor"
        "giphy"
        "klipy"
      ];
    };
    HomeTyping.enabled = true;
    ImageFilename = {
      enabled = true;
      showFullUrl = false;
    };
    ImageZoom = {
      enabled = true;
      invertScroll = true;
      nearestNeighbour = false;
      saveZoomValues = true;
      size = 344.04761904761904;
      square = false;
      zoom = 3.349333333333334;
      zoomSpeed = 0.9788888888888889;
    };
    MemberCount = {
      enabled = true;
      memberList = true;
      toolTip = true;
      voiceActivity = true;
    };
    Moyai = {
      enabled = true;
      ignoreBlocked = true;
      ignoreBots = true;
      quality = "HD";
      triggerWhenUnfocused = true;
      volume = 0.5;
    };
    NoF1.enabled = true;
    NoPendingCount = {
      enabled = true;
      hideFriendRequestsCount = true;
      hideMessageRequestsCount = true;
      hidePremiumOffersCount = true;
    };
    NoTrack = {
      enabled = true;
      disableAnalytics = true;
    };
    PetPet.enabled = true;
    PlatformIndicators = {
      enabled = true;
      ConsoleIcon = "suncord";
      colorMobileIndicator = true;
      list = true;
      messages = true;
      profiles = true;
      showBots = false;
    };
    PlatformSpoofer = {
      enabled = true;
      platform = "desktop";
    };
    ReactionTimestamps.enabled = true;
    RelationshipNotifier = {
      enabled = true;
      friendRequestCancels = true;
      friends = true;
      groups = true;
      notices = true;
      offlineRemovals = true;
      servers = true;
    };
    ReplaceGoogleSearch = {
      enabled = true;
      replacementEngine = "Startpage";
    };
    ServerInfo.enabled = true;
    Settings = {
      enabled = true;
      includeVencordInfoWhenCopying = true;
      settingsLocation = "aboveNitro";
    };
    ShikiCodeblocks = {
      enabled = true;
      bgOpacity = 100;
      tryHljs = "PRIMARY";
      useDevIcon = "COLOR";
    };
    ShowHiddenChannels = {
      enabled = true;
      channelStyle = 0;
      defaultAllowedUsersAndRolesDropdownState = true;
      showMode = 0;
    };
    ShowHiddenThings = {
      enabled = true;
      showInvitesPaused = true;
      showModView = true;
      showTimeouts = true;
    };
    ShowResourceChannels.enabled = true;
    SilentMessageToggle = {
      enabled = true;
      persistState = "none";
    };
    SilentTyping = {
      enabled = true;
      alwaysEnableInActiveVoiceChat = false;
      chatContextMenu = true;
      chatIcon = true;
      chatIconLeftClickAction = "channel";
      chatIconMiddleClickAction = "settings";
      chatIconRightClickAction = "global";
      defaultHidden = true;
      disabledLocations = "1385605653548236860, 1012079981695864834";
      enabledGlobally = true;
      enabledLocations = "";
      hideChatBoxTypingIndicators = false;
      hideMembersListTypingIndicators = false;
      temporaryEnableThresholdDirectMessages = 0;
      temporaryEnableThresholdServers = 0;
    };
    SongLink = {
      enabled = true;
      includeMetadata = true;
      userCountry = "US";
      servicesSettings = {
        spotify = {
          enabled = true;
          openInNative = true;
        };
        soundcloud = {
          enabled = true;
          openInNative = false;
        };
      };
    };
    SpotifyActivityToggle = {
      enabled = true;
      location = "PANEL";
    };
    SpotifyCrack = {
      enabled = true;
      keepSpotifyActivityOnIdle = false;
      noSpotifyAutoPause = true;
    };
    SplitLargeMessages = {
      enabled = true;
      maxLength = 0;
    };
    SupportHelper.enabled = true;
    UserVoiceShow = {
      enabled = true;
      showInMemberList = true;
      showInMessages = true;
      showInUserProfileModal = true;
    };
    ValidReply.enabled = true;
    ViewIcons = {
      enabled = true;
      format = "webp";
      imgSize = "1024";
    };
    VoiceChannelLog = {
      enabled = true;
      ignoreBlockedUsers = false;
      logActivity = true;
      logJoinLeave = true;
      logMuteDeafen = true;
      logSoundboard = true;
      logStream = true;
      logVideo = true;
    };
    VoiceChatDoubleClick.enabled = true;
    VoiceChatUtilities = {
      enabled = true;
      waitAfter = 5;
      waitSeconds = 2;
    };
    VoiceDownload.enabled = true;
    VoiceMessages.enabled = true;
    VoiceMessagesInBackground.enabled = true;
    VoiceStats.enabled = true;
    VolumeBooster = {
      enabled = true;
      multiplier = 4;
    };
    WaitForSlot.enabled = true;
    WebContextMenus.enabled = true;
    WebScreenShareFixes.enabled = true;
    ZipPreview.enabled = true;
  };
}
