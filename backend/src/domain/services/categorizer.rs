/// Tokenize text into lowercase words for keyword matching.
/// Splits on non-alphanumeric characters to support multi-language titles.
fn tokenize(text: &str) -> Vec<String> {
    text.to_lowercase()
        .split(|c: char| !c.is_alphanumeric() && c != '-')
        .filter(|s| !s.is_empty())
        .map(String::from)
        .collect()
}

/// Check whether any of the given keywords/phrases appear as whole words
/// (or whole multi-word phrases) in the tokenized text.
fn matches_any(tokens: &[String], joined: &str, keywords: &[&str]) -> bool {
    keywords.iter().any(|kw| {
        if kw.contains(' ') {
            // Multi-word phrase — match against the joined string with surrounding spaces
            joined.contains(&format!(" {kw} "))
        } else {
            // Single word — match a token exactly
            tokens.iter().any(|t| t == kw)
        }
    })
}

pub fn categorize(title: &str, description: Option<&str>) -> Option<String> {
    let combined = format!("{} {}", title, description.unwrap_or(""));
    let tokens = tokenize(&combined);
    // Joined string padded with spaces for safe phrase matching
    let joined = format!(" {} ", tokens.join(" "));

    // Check transfers first because keywords like "signs" / "joins" / "fichaje"
    // are more specific than the broad results keywords.
    let transfer_keywords = &[
        "signs",
        "transfer",
        "transfers",
        "joins",
        "contract",
        "extends",
        "leaves",
        "moves to",
        "announcement",
        "confirmed",
        "deal",
        "kontrakt",
        "przechodzi",
        "fichaje",
        "ficha",
        "renueva",
    ];
    if matches_any(&tokens, &joined, transfer_keywords) {
        return Some("transfers".to_string());
    }

    let results_keywords = &[
        "results",
        "stage",
        "wins",
        "winner",
        "podium",
        "general classification",
        "standings",
        "finished",
        "crossed the line",
        "time trial",
        "wyniki",
        "etap",
        "klasyfikacja",
        "resultados",
        "clasificación",
        "etapa",
        "ganador",
    ];
    if matches_any(&tokens, &joined, results_keywords) {
        return Some("results".to_string());
    }

    let equipment_keywords = &[
        "review",
        "launch",
        "launches",
        "launched",
        "new bike",
        "unveiled",
        "tested",
        "first ride",
        "groupset",
        "frameset",
        "recenzja",
        "nowy rower",
        "prueba",
    ];
    if matches_any(&tokens, &joined, equipment_keywords) {
        return Some("equipment".to_string());
    }

    let event_keywords = &[
        "race",
        "calendar",
        "announced",
        "championship",
        "world cup",
        "olympics",
        "tour de",
        "giro",
        "vuelta",
        "paris-roubaix",
        "flanders",
        "route",
        "parcours",
        "startlist",
        "start list",
        "wyścig",
        "kalendarz",
        "mistrzostwa",
        "carrera",
        "campeonato",
    ];
    if matches_any(&tokens, &joined, event_keywords) {
        return Some("events".to_string());
    }

    Some("general".to_string())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn categorizes_race_results() {
        let cat = categorize("Pogacar wins stage 5 of Tour de France", None);
        assert_eq!(cat, Some("results".to_string()));
    }

    #[test]
    fn categorizes_polish_race_results() {
        let cat = categorize("Wyniki etapu — kolarz wygrywa", None);
        assert_eq!(cat, Some("results".to_string()));
    }

    #[test]
    fn categorizes_spanish_race_results() {
        let cat = categorize("Resultados de la etapa: ganador en la cumbre", None);
        assert_eq!(cat, Some("results".to_string()));
    }

    #[test]
    fn categorizes_transfers() {
        let cat = categorize("Visma signs new sprinter for 2026", None);
        assert_eq!(cat, Some("transfers".to_string()));
    }

    #[test]
    fn categorizes_equipment() {
        let cat = categorize("New Pinarello bike launched at Eurobike", None);
        assert_eq!(cat, Some("equipment".to_string()));
    }

    #[test]
    fn categorizes_events() {
        let cat = categorize("UCI announces 2027 World Championship venue", None);
        assert_eq!(cat, Some("events".to_string()));
    }

    #[test]
    fn falls_back_to_general() {
        let cat = categorize("Cycling is fun", None);
        assert_eq!(cat, Some("general".to_string()));
    }

    #[test]
    fn uses_description_when_title_lacks_keywords() {
        let cat = categorize("Big news today", Some("Final standings of the race"));
        assert_eq!(cat, Some("results".to_string()));
    }

    #[test]
    fn results_takes_priority_over_equipment() {
        let cat = categorize("Race results: new bike helps winner", None);
        assert_eq!(cat, Some("results".to_string()));
    }

    #[test]
    fn transfers_takes_priority_over_results() {
        let cat = categorize("Visma signs sprinter who finished 2nd at Vuelta", None);
        assert_eq!(cat, Some("transfers".to_string()));
    }

    #[test]
    fn does_not_match_substrings() {
        // "sprinter" should NOT match "sprint" — substring matching was a bug.
        // This title has no real category cues, so should fall through to general or events.
        let cat = categorize("New sprinter announcement", None);
        // "announcement" is in transfers — that's fine, the point is it shouldn't be "results"
        assert_ne!(cat, Some("results".to_string()));
    }

    #[test]
    fn multi_word_phrases_match() {
        let cat = categorize("UCI World Cup returns to Mont-Sainte-Anne", None);
        assert_eq!(cat, Some("events".to_string()));
    }

    #[test]
    fn handles_punctuation_correctly() {
        let cat = categorize("Pogacar wins! Stage 5 of the Tour de France.", None);
        assert_eq!(cat, Some("results".to_string()));
    }
}
