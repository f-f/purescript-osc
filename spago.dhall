{ name = "osc"
, dependencies =
    [ "console"
    , "effect"
    , "foreign"
    , "generics-rep"
    , "psci-support"
    , "simple-json"
    , "simple-json-generics"
    ]
, packages = ./packages.dhall
, sources = [ "src/**/*.purs" ]
}
