import ProjectDescription

let appVersion = Environment.appVersion.getString(default: "1.0.0")
let buildVersion = Environment.buildNumber.getString(default: "1")
let tvOSDeploymentTarget = "26.0"

let developmentTeam = Environment.developmentTeam.getString(default: "")
let forceAppGroups = Environment.forceAppGroups.getString(default: "").isEmpty ? "NO" : "YES"

private func baseSettings() -> SettingsDictionary {
  var baseSettings: SettingsDictionary = [
    "CURRENT_PROJECT_VERSION": .string(buildVersion),
    "ICHIME_FORCE_APP_GROUPS": .string(forceAppGroups),
    "INFOPLIST_KEY_CFBundleDisplayName": "Ichime",
    "INFOPLIST_KEY_LSApplicationCategoryType": "public.app-category.entertainment",
    "MARKETING_VERSION": .string(appVersion),
    "SWIFT_STRICT_CONCURRENCY": "complete",
    "SWIFT_VERSION": "6.0",
  ]

  if !developmentTeam.isEmpty {
    baseSettings["DEVELOPMENT_TEAM"] = .string(developmentTeam)
  }

  return baseSettings
}

private func extensionSafeFrameworkSettings() -> Settings {
  .settings(
    base: [
      "APPLICATION_EXTENSION_API_ONLY": "YES"
    ]
  )
}

let packageDependencies: [TargetDependency] = [
  .external(name: "Anime365Kit"),
  .external(name: "AppdbFramework"),
  .external(name: "Collections"),
  .external(name: "JikanApiClient"),
  .external(name: "ShikimoriApiClient"),
  .external(name: "ThirdPartyVideoPlayer"),
]

let domainDependencies: [TargetDependency] = [
  .target(name: "IchimeCore"),
  .target(name: "IchimePreferences"),
  .target(name: "IchimeAnime365"),
  .target(name: "IchimeShow"),
  .target(name: "IchimeCalendar"),
  .target(name: "IchimeCurrentlyWatching"),
  .target(name: "IchimeEpisode"),
  .target(name: "IchimeMoment"),
  .target(name: "IchimeMyLists"),
  .target(name: "IchimeProfile"),
  .target(name: "IchimeVideoPlayer"),
]

let appGroupEntitlements: Entitlements = .dictionary([
  "com.apple.security.application-groups": ["group.dev.midorinome.ichime.group"]
])

let project = Project(
  name: "Ichime",
  options: .options(
    defaultKnownRegions: ["ru"],
    developmentRegion: "ru",
    textSettings: .textSettings(indentWidth: 2)
  ),
  settings: .settings(
    base: baseSettings(),
    configurations: [
      .debug(name: .debug),
      .release(name: .release),
    ]
  ),
  targets: [
    .target(
      name: "IchimeCore",
      destinations: .tvOS,
      product: .framework,
      bundleId: "dev.midorinome.ichime.core",
      deploymentTargets: .tvOS(tvOSDeploymentTarget),
      sources: ["Modules/IchimeCore/Sources/**"],
      dependencies: [
        .external(name: "AppdbFramework")
      ],
      settings: extensionSafeFrameworkSettings()
    ),
    .target(
      name: "IchimePreferences",
      destinations: .tvOS,
      product: .framework,
      bundleId: "dev.midorinome.ichime.preferences",
      deploymentTargets: .tvOS(tvOSDeploymentTarget),
      sources: ["Modules/IchimePreferences/Sources/**"],
      dependencies: [
        .external(name: "Collections")
      ],
      settings: extensionSafeFrameworkSettings()
    ),
    .target(
      name: "IchimeAnime365",
      destinations: .tvOS,
      product: .framework,
      bundleId: "dev.midorinome.ichime.anime365",
      deploymentTargets: .tvOS(tvOSDeploymentTarget),
      sources: ["Modules/IchimeAnime365/Sources/**"],
      dependencies: [
        .external(name: "Anime365Kit"),
        .external(name: "Collections"),
        .target(name: "IchimeCore"),
      ],
      settings: extensionSafeFrameworkSettings()
    ),
    .target(
      name: "IchimeShow",
      destinations: .tvOS,
      product: .framework,
      bundleId: "dev.midorinome.ichime.show",
      deploymentTargets: .tvOS(tvOSDeploymentTarget),
      sources: ["Modules/IchimeShow/Sources/**"],
      dependencies: [
        .external(name: "Anime365Kit"),
        .external(name: "Collections"),
        .external(name: "JikanApiClient"),
        .external(name: "ShikimoriApiClient"),
        .target(name: "IchimeAnime365"),
        .target(name: "IchimePreferences"),
      ],
      settings: extensionSafeFrameworkSettings()
    ),
    .target(
      name: "IchimeCalendar",
      destinations: .tvOS,
      product: .framework,
      bundleId: "dev.midorinome.ichime.calendar",
      deploymentTargets: .tvOS(tvOSDeploymentTarget),
      sources: ["Modules/IchimeCalendar/Sources/**"],
      dependencies: [
        .external(name: "Collections"),
        .external(name: "ShikimoriApiClient"),
        .target(name: "IchimeAnime365"),
        .target(name: "IchimeShow"),
      ],
      settings: extensionSafeFrameworkSettings()
    ),
    .target(
      name: "IchimeCurrentlyWatching",
      destinations: .tvOS,
      product: .framework,
      bundleId: "dev.midorinome.ichime.currentlywatching",
      deploymentTargets: .tvOS(tvOSDeploymentTarget),
      sources: ["Modules/IchimeCurrentlyWatching/Sources/**"],
      dependencies: [
        .external(name: "Anime365Kit"),
        .external(name: "Collections"),
        .target(name: "IchimeAnime365"),
        .target(name: "IchimeShow"),
      ],
      settings: extensionSafeFrameworkSettings()
    ),
    .target(
      name: "IchimeEpisode",
      destinations: .tvOS,
      product: .staticFramework,
      bundleId: "dev.midorinome.ichime.episode",
      deploymentTargets: .tvOS(tvOSDeploymentTarget),
      sources: ["Modules/IchimeEpisode/Sources/**"],
      dependencies: [
        .external(name: "Anime365Kit"),
        .external(name: "Collections"),
        .external(name: "JikanApiClient"),
        .target(name: "IchimeAnime365"),
        .target(name: "IchimePreferences"),
        .target(name: "IchimeShow"),
      ]
    ),
    .target(
      name: "IchimeMoment",
      destinations: .tvOS,
      product: .staticFramework,
      bundleId: "dev.midorinome.ichime.moment",
      deploymentTargets: .tvOS(tvOSDeploymentTarget),
      sources: ["Modules/IchimeMoment/Sources/**"],
      dependencies: [
        .external(name: "Anime365Kit"),
        .external(name: "Collections"),
        .target(name: "IchimeAnime365"),
        .target(name: "IchimeShow"),
      ]
    ),
    .target(
      name: "IchimeMyLists",
      destinations: .tvOS,
      product: .staticFramework,
      bundleId: "dev.midorinome.ichime.mylists",
      deploymentTargets: .tvOS(tvOSDeploymentTarget),
      sources: ["Modules/IchimeMyLists/Sources/**"],
      dependencies: [
        .external(name: "Anime365Kit"),
        .external(name: "Collections"),
        .target(name: "IchimeAnime365"),
        .target(name: "IchimeShow"),
      ]
    ),
    .target(
      name: "IchimeProfile",
      destinations: .tvOS,
      product: .staticFramework,
      bundleId: "dev.midorinome.ichime.profile",
      deploymentTargets: .tvOS(tvOSDeploymentTarget),
      sources: ["Modules/IchimeProfile/Sources/**"],
      dependencies: [
        .external(name: "Anime365Kit"),
        .target(name: "IchimeAnime365"),
        .target(name: "IchimeMyLists"),
      ]
    ),
    .target(
      name: "IchimeVideoPlayer",
      destinations: .tvOS,
      product: .staticFramework,
      bundleId: "dev.midorinome.ichime.videoplayer",
      deploymentTargets: .tvOS(tvOSDeploymentTarget),
      sources: ["Modules/IchimeVideoPlayer/Sources/**"]
    ),
    .target(
      name: "Ichime",
      destinations: .tvOS,
      product: .app,
      bundleId: "dev.midorinome.ichime",
      deploymentTargets: .tvOS(tvOSDeploymentTarget),
      infoPlist: .extendingDefault(with: [
        "CFBundleShortVersionString": "$(MARKETING_VERSION)",
        "CFBundleVersion": "$(CURRENT_PROJECT_VERSION)",
        "CFBundleURLTypes": [
          [
            "CFBundleURLSchemes": ["ichime"]
          ]
        ],
        "LSApplicationQueriesSchemes": [
          "infuse",
          "vlc-x-callback",
        ],
        "ICHForceAppGroups": "$(ICHIME_FORCE_APP_GROUPS)",
        "UIRequiredDeviceCapabilities": ["arm64"],
      ]),
      sources: [
        "Ichime/Sources/**"
      ],
      resources: [
        "Ichime/Resources/AppIcon.icon",
        "Ichime/Resources/Assets.xcassets",
        "Ichime/Resources/Settings.bundle",
      ],
      entitlements: appGroupEntitlements,
      dependencies: packageDependencies + domainDependencies + [
        .target(name: "TopShelf")
      ],
      settings: .settings(
        base: [
          "ASSETCATALOG_COMPILER_ALTERNATE_APPICON_NAMES": """
          "App Icon - Gawr Gura"
          "App Icon - Hentai 365"
          """
        ]
      )
    ),
    .target(
      name: "TopShelf",
      destinations: .tvOS,
      product: .tvTopShelfExtension,
      bundleId: "dev.midorinome.ichime.TopShelf",
      deploymentTargets: .tvOS(tvOSDeploymentTarget),
      infoPlist: .extendingDefault(with: [
        "CFBundleDisplayName": "$(PRODUCT_NAME) TopShelf",
        "CFBundleShortVersionString": "$(MARKETING_VERSION)",
        "CFBundleVersion": "$(CURRENT_PROJECT_VERSION)",
        "ICHForceAppGroups": "$(ICHIME_FORCE_APP_GROUPS)",
        "NSExtension": [
          "NSExtensionPointIdentifier": "com.apple.tv-top-shelf",
          "NSExtensionPrincipalClass": "$(PRODUCT_MODULE_NAME).ContentProvider",
        ],
        "UIRequiredDeviceCapabilities": ["arm64"],
      ]),
      sources: [
        "TopShelf/Sources/**"
      ],
      entitlements: appGroupEntitlements,
      dependencies: [
        .external(name: "ShikimoriApiClient"),
        .target(name: "IchimeAnime365"),
        .target(name: "IchimeCalendar"),
        .target(name: "IchimeCore"),
        .target(name: "IchimeCurrentlyWatching"),
      ],
      settings: .settings(
        base: [
          "APPLICATION_EXTENSION_API_ONLY": "YES",
          "LD_RUNPATH_SEARCH_PATHS": [
            "$(inherited)",
            "@executable_path/Frameworks",
            "@executable_path/../../Frameworks",
          ],
        ]
      )
    ),
  ],
  additionalFiles: [
    ".editorconfig",
    ".env.example",
    ".gitignore",
    ".github/**",
    ".periphery.yml",
    ".swift-format",
    ".swiftformat",
    ".swiftlint.yml",
    "Makefile",
    "README.md",
  ]
)
