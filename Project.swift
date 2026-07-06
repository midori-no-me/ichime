import ProjectDescription

let appVersion = "1.12.3"
let buildVersion = "101203"
let tvOSDeploymentTarget = "26.0"

let developmentTeam = Environment.developmentTeam.getString(default: "")

private func baseSettings() -> SettingsDictionary {
  var baseSettings: SettingsDictionary = [
    "CURRENT_PROJECT_VERSION": .string(buildVersion),
    "INFOPLIST_KEY_CFBundleDisplayName": "Ichime",
    "INFOPLIST_KEY_LSApplicationCategoryType": "public.app-category.entertainment",
    "MARKETING_VERSION": .string(appVersion),
  ]

  if !developmentTeam.isEmpty {
    baseSettings["DEVELOPMENT_TEAM"] = .string(developmentTeam)
  }

  return baseSettings
}

let packageDependencies: [TargetDependency] = [
  .external(name: "Anime365Kit"),
  .external(name: "Collections"),
  .external(name: "DITranquillity"),
  .external(name: "JikanApiClient"),
  .external(name: "ShikimoriApiClient"),
  .external(name: "ThirdPartyVideoPlayer"),
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
      .debug(
        name: .debug,
        settings: [
          "INFOPLIST_KEY_CFBundleDisplayName": "Ichime (dev)"
        ]
      ),
      .release(name: .release),
    ]
  ),
  targets: [
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
        "UIRequiredDeviceCapabilities": ["arm64"],
      ]),
      sources: [
        .glob(
          "Ichime/Sources/**",
          excluding: ["Ichime/Sources/TopShelf/**"]
        )
      ],
      resources: [
        "Ichime/Resources/Assets.xcassets",
        "Ichime/Resources/Settings.bundle",
      ],
      entitlements: appGroupEntitlements,
      dependencies: packageDependencies + [
        .target(name: "TopShelf")
      ],
      settings: .settings(
        base: [
          "ASSETCATALOG_COMPILER_ALTERNATE_APPICON_NAMES": """
          "App Icon - Gawr Gura"
          "App Icon - Hentai 365"
          """
        ],
        debug: [
          "ASSETCATALOG_COMPILER_APPICON_NAME": "App Icon & Top Shelf Image (Debug)"
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
        "NSExtension": [
          "NSExtensionPointIdentifier": "com.apple.tv-top-shelf",
          "NSExtensionPrincipalClass": "$(PRODUCT_MODULE_NAME).ContentProvider",
        ],
        "UIRequiredDeviceCapabilities": ["arm64"],
      ]),
      sources: [
        "Ichime/Sources/Anime365/Anime365BaseURL.swift",
        "Ichime/Sources/Anime365/Anime365KitFactory.swift",
        "Ichime/Sources/Calendar/Model/ShowFromCalendarWithExactReleaseDate.swift",
        "Ichime/Sources/Calendar/Model/ShowsFromCalendarGroupedByDate.swift",
        "Ichime/Sources/Calendar/ShowReleaseSchedule.swift",
        "Ichime/Sources/CurrentlyWatching/CurrentlyWatchingService.swift",
        "Ichime/Sources/CurrentlyWatching/Type/EpisodeFromCurrentlyWatchingList.swift",
        "Ichime/Sources/DependencyInjection/ServiceLocator.swift",
        "Ichime/Sources/Show/Type/ShowName.swift",
        "Ichime/Sources/TopShelf/**",
        "Ichime/Sources/Utils/DateUtils.swift",
      ],
      entitlements: appGroupEntitlements,
      dependencies: [
        .external(name: "Anime365Kit"),
        .external(name: "Collections"),
        .external(name: "JikanApiClient"),
        .external(name: "ShikimoriApiClient"),
      ],
      settings: .settings(
        base: [
          "LD_RUNPATH_SEARCH_PATHS": [
            "$(inherited)",
            "@executable_path/Frameworks",
            "@executable_path/../../Frameworks",
          ]
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
