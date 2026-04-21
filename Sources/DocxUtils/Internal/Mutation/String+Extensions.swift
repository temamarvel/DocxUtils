extension String {
    func prefixCharacters(_ count: Int) -> String {
        String(prefix(max(0, count)))
    }

    func suffixCharacters(from offset: Int) -> String {
        guard offset > 0 else { return self }
        guard offset < count else { return "" }
        let index = self.index(startIndex, offsetBy: offset)
        return String(self[index...])
    }
}
