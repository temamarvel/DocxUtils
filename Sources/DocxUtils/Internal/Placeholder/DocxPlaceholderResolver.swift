enum PlaceholderResolution {
    case replace(String)
    case keepOriginal
    case replaceWithEmptyString
    case missingRequired(String)
}

struct DocxPlaceholderResolver {
    let values: [String: String]
    let missingKeyPolicy: MissingKeyPolicy

    func resolve(key: String) -> PlaceholderResolution {
        if let value = values[key] {
            return .replace(value)
        }

        switch missingKeyPolicy {
        case .error:
            return .missingRequired(key)
        case .keepPlaceholder:
            return .keepOriginal
        case .replaceWithEmptyString:
            return .replaceWithEmptyString
        }
    }
}
