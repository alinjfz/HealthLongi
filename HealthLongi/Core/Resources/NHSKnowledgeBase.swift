import Foundation

/// Curated NHS patient-facing guidance injected into AI prompts. AI must cite these topic IDs.
struct NHSKnowledgeTopic: Codable, Sendable, Equatable, Identifiable {
    let id: String
    let title: String
    let url: URL
    let excerpt: String
    let thresholds: String?

    var link: NHSLink {
        NHSLink(id: id, title: title, url: url, description: excerpt)
    }
}

enum NHSKnowledgeBase {
    static let version = "2026.06"

    static let all: [NHSKnowledgeTopic] = [
        NHSKnowledgeTopic(
            id: "physical_activity",
            title: "Physical activity guidelines",
            url: URL(string: "https://www.nhs.uk/live-well/exercise/")!,
            excerpt: """
            Adults should aim for at least 150 minutes of moderate intensity activity a week, or 75 minutes of vigorous intensity, spread over 4 to 5 days. \
            Moving more can lower risk of heart disease, stroke, type 2 diabetes and some cancers. Break up long sitting periods. \
            Walking counts — you do not need a gym.
            """,
            thresholds: "150+ minutes moderate activity per week"
        ),
        NHSKnowledgeTopic(
            id: "nhs_active_10",
            title: "NHS Active 10 & walking",
            url: URL(string: "https://www.nhs.uk/live-well/exercise/running-and-aerobic-exercises/get-running-with-couch-to-5k/")!,
            excerpt: """
            Brisk walking counts as moderate activity. Even 10 minutes at a time can help. \
            Building daily walking habits supports heart health and mood without needing special equipment.
            """,
            thresholds: nil
        ),
        NHSKnowledgeTopic(
            id: "sleep",
            title: "Sleep and tiredness",
            url: URL(string: "https://www.nhs.uk/live-well/sleep-and-tiredness/")!,
            excerpt: """
            Most adults need 7 to 9 hours of sleep per night. Poor sleep affects mood, concentration and physical health. \
            Regular sleep times, reducing screens before bed, and a dark quiet bedroom can help. \
            See a GP if sleep problems persist for weeks and affect daily life.
            """,
            thresholds: "7–9 hours per night for adults"
        ),
        NHSKnowledgeTopic(
            id: "anxiety",
            title: "Anxiety",
            url: URL(string: "https://www.nhs.uk/mental-health/feelings-symptoms-behaviours/feelings-and-symptoms/anxiety-fear-panic/")!,
            excerpt: """
            Anxiety is a feeling of unease, worry or fear. It is normal to feel anxious sometimes, but if it is affecting daily life, help is available. \
            Self-help includes breathing exercises, staying active, limiting caffeine and alcohol, and talking to someone you trust. \
            NHS talking therapies are free and you can self-refer in England.
            """,
            thresholds: nil
        ),
        NHSKnowledgeTopic(
            id: "depression",
            title: "Depression",
            url: URL(string: "https://www.nhs.uk/mental-health/conditions/clinical-depression/")!,
            excerpt: """
            Depression is more than feeling down for a few days. Symptoms can include low mood, loss of interest, poor sleep, low energy and difficulty concentrating. \
            Treatment may include talking therapies, lifestyle changes, or medication from a GP. \
            Contact your GP if symptoms last more than a few weeks or affect work and relationships.
            """,
            thresholds: nil
        ),
        NHSKnowledgeTopic(
            id: "nhs_talking_therapies",
            title: "NHS Talking Therapies",
            url: URL(string: "https://www.nhs.uk/nhs-services/mental-health-services/find-nhs-talking-therapies-for-anxiety-and-depression/")!,
            excerpt: """
            NHS talking therapies (IAPT) offer free evidence-based treatment for anxiety and depression in England. \
            You can self-refer without seeing a GP first. Options include CBT, counselling and guided self-help.
            """,
            thresholds: nil
        ),
        NHSKnowledgeTopic(
            id: "nhs_mental_health",
            title: "NHS Mental health",
            url: URL(string: "https://www.nhs.uk/mental-health/")!,
            excerpt: """
            NHS mental health services include self-help guides, urgent support, talking therapies and specialist care. \
            Good mental health practices include staying connected, physical activity, sleep and limiting alcohol.
            """,
            thresholds: nil
        ),
        NHSKnowledgeTopic(
            id: "nhs_heart_health",
            title: "Coronary heart disease",
            url: URL(string: "https://www.nhs.uk/conditions/coronary-heart-disease/")!,
            excerpt: """
            Coronary heart disease is caused when the heart's blood vessels narrow. Risk factors include smoking, high blood pressure, high cholesterol, diabetes, inactivity and obesity. \
            Lifestyle changes — quitting smoking, healthier diet, more activity — reduce risk. \
            See a GP for a cardiovascular risk assessment if concerned.
            """,
            thresholds: nil
        ),
        NHSKnowledgeTopic(
            id: "high_blood_pressure",
            title: "High blood pressure",
            url: URL(string: "https://www.nhs.uk/conditions/high-blood-pressure-hypertension/")!,
            excerpt: """
            High blood pressure (hypertension) often has no symptoms but raises risk of heart attack and stroke. \
            Readings of 140/90 mmHg or higher on several occasions usually need GP review. \
            Lifestyle changes include less salt, more activity, healthy weight, and limiting alcohol.
            """,
            thresholds: "140/90 mmHg or higher — discuss with GP"
        ),
        NHSKnowledgeTopic(
            id: "high_cholesterol",
            title: "High cholesterol",
            url: URL(string: "https://www.nhs.uk/conditions/high-cholesterol/")!,
            excerpt: """
            High cholesterol increases risk of heart attack and stroke. Total cholesterol above 5 mmol/L is often considered high; \
            LDL above 3 mmol/L may need attention depending on overall risk. \
            A healthy diet low in saturated fat, more activity, and not smoking help. GP may recommend a statin based on QRISK assessment.
            """,
            thresholds: "Total cholesterol ideally below 5.0 mmol/L"
        ),
        NHSKnowledgeTopic(
            id: "nhs_diabetes_prevention",
            title: "Type 2 diabetes",
            url: URL(string: "https://www.nhs.uk/conditions/type-2-diabetes/")!,
            excerpt: """
            Type 2 diabetes is a lifelong condition where blood sugar is too high. Risk factors include weight, inactivity, family history and age. \
            HbA1c of 48 mmol/mol (6.5%) or higher on two occasions confirms diabetes; 42–47 mmol/mol (6.0–6.4%) is often called pre-diabetes. \
            Losing weight, eating well and moving more can prevent or delay type 2 diabetes. NHS Diabetes Prevention Programme may be offered.
            """,
            thresholds: "HbA1c below 6.0% (42 mmol/mol) is typical for people without diabetes"
        ),
        NHSKnowledgeTopic(
            id: "nhs_healthy_weight",
            title: "Healthy weight",
            url: URL(string: "https://www.nhs.uk/live-well/healthy-weight/")!,
            excerpt: """
            BMI between 18.5 and 24.9 is considered healthy for most adults. BMI 25–29.9 is overweight; 30+ is obese. \
            Waist size also matters — over 94 cm (men) or 80 cm (women) raises health risks. \
            Gradual sustainable changes to diet and activity are recommended over crash diets.
            """,
            thresholds: "BMI 18.5–24.9 healthy range; waist over 94 cm (men) or 80 cm (women) increases risk"
        ),
        NHSKnowledgeTopic(
            id: "alcohol",
            title: "Alcohol support",
            url: URL(string: "https://www.nhs.uk/live-well/alcohol-advice/")!,
            excerpt: """
            To keep health risks from alcohol low, do not regularly drink more than 14 units per week. \
            Spread drinking over 3 or more days with several drink-free days. \
            If you are worried about drinking, talk to your GP — support is available.
            """,
            thresholds: "No more than 14 units per week spread across the week"
        ),
        NHSKnowledgeTopic(
            id: "vitamin_d",
            title: "Vitamin D",
            url: URL(string: "https://www.nhs.uk/conditions/vitamins-and-minerals/vitamin-d/")!,
            excerpt: """
            Vitamin D helps keep bones, teeth and muscles healthy. From October to March, adults should consider a daily 10 microgram supplement. \
            Low levels can cause tiredness and bone pain. Blood levels below 25 nmol/L indicate deficiency; discuss supplements or treatment with a GP.
            """,
            thresholds: "Below 25 nmol/L — deficiency; consider 10 µg daily supplement Oct–March"
        ),
        NHSKnowledgeTopic(
            id: "stress_wellbeing",
            title: "Stress and wellbeing",
            url: URL(string: "https://www.nhs.uk/mental-health/feelings-symptoms-behaviours/feelings-and-symptoms/stress/")!,
            excerpt: """
            Stress is the body's reaction to pressure. Chronic stress affects sleep, mood and physical health. \
            NHS recommends problem-solving, staying active, connecting with others, and making time to relax. \
            See a GP if stress is overwhelming or persistent.
            """,
            thresholds: nil
        ),
        NHSKnowledgeTopic(
            id: "nhs_111",
            title: "NHS 111",
            url: URL(string: "https://111.nhs.uk/")!,
            excerpt: """
            NHS 111 online or by phone can help if you need urgent medical help but it is not a life-threatening emergency. \
            Use for urgent mental health crisis guidance or when unsure whether to see a GP.
            """,
            thresholds: nil
        ),
        NHSKnowledgeTopic(
            id: "find_gp",
            title: "Find a GP",
            url: URL(string: "https://www.nhs.uk/service-search/find-a-gp/")!,
            excerpt: """
            Your GP surgery is the first point of contact for non-emergency health concerns, repeat prescriptions, referrals and preventive checks. \
            Book an appointment to discuss blood test results, blood pressure, mood changes or lifestyle support.
            """,
            thresholds: nil
        )
    ]

    static var byID: [String: NHSKnowledgeTopic] {
        Dictionary(uniqueKeysWithValues: all.map { ($0.id, $0) })
    }

    static func topic(id: String) -> NHSKnowledgeTopic? { byID[id] }

    static func links(forTopicIDs ids: [String]) -> [NHSLink] {
        ids.compactMap { byID[$0]?.link }
    }
}
