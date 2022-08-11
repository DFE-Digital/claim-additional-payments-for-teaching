module Dqt
  module Matchers
    module EarlyCareerPayments
      ELIGIBLE_JAC_CODES = {
        chemistry: %w[
          F1
        ],
        foreign_languages: %w[
          Q1
          Q4
          Q5
          Q6
          Q7
          Q8
          Q9
          R1
          R2
          R3
          R4
          R5
          R6
          R7
          R8
          R9
          T1
          T2
          T4
          T5
          T6
          T7
          T8
          Z0
          ZZ
        ],
        mathematics: %w[
          G1
          G4
          G5
          G9
        ],
        physics: %w[
          F3
          F6
          F9
        ]
      }.freeze

      # match HECOS NAMES to all codes in order
      ELIGIBLE_HECOS_CODES = {
        chemistry: %w[
          100417
          101038
        ],
        foreign_languages: %w[
          100321
          100323
          100326
          100329
          100330
          100332
          100333
          101142
          101420
        ],
        mathematics: %w[
          100403
        ],
        physics: %w[
          100425
          101060
        ]
      }.freeze

      # match JAC CODES to all names in order
      ELIGIBLE_JAC_NAMES = {
        chemistry: [
          # F1
          "Applied Chemistry",
          "Applied Chemistry",
          "Chemical Sciences",
          "Chemical Technology",
          "Chemistry",
          "Environmental Chemistry",
          "Inorganic Chemistry",
          "Science-Chemistry-Bath Ude"
        ],
        foreign_languages: [
          # Q1
          "Foreign & Community Languages",
          "Foreign Languages",
          # Q4
          "Ancient language studies not elsewhere classified",
          # Q5
          "Celtic Languages",
          "Gaelic",
          "Irish",
          "Ling,lit & Cult Herit-Welsh",
          "Welsh",
          "Welsh and Drama",
          "Welsh and Welsh Studies",
          "Welsh As A Modern Language",
          "Welsh As A Second Language",
          "Welsh Literature",
          "Welsh Studies",
          # Q6
          "Latin",
          "Latin Language",
          # Q7
          "Ancient Greek",
          "Classical Greek Language",
          "Greek (Classical)",
          # Q8
          "Ancient Greek Lang & Lit",
          "Classical Languages",
          # Q9
          "French and Spanish",
          "German With French",
          "Mfl(French, Spanish, German)",
          "Spanish With French",
          "Teach Eng -Speakers Other Lang",
          # R1
          "French",
          "French and German",
          "French Lang and Literature",
          "French Language & Studies",
          "French Literature",
          "French Studies (In Translation)",
          "Frenchlang and Contemp Studs",
          # R2
          "German",
          "German Language & Studies",
          "German Literature",
          # R3
          "Italian",
          "Italian Language & Studies",
          # R4
          "Hispanic",
          "Hispanic Studies",
          "Spanish",
          "Spanish Language & Studies",
          "Spanish Studies (In Translation)",
          # R5
          "Portuguese", # F500
          "Portuguese", # F5000
          # R6
          "Latin American Languages",
          # R7
          "Danish",
          "Norwegian",
          "Russian",
          "Swedish",
          # R8
          "Modern Foreign Languages",
          "French Lang, Lit & Cult",
          "French With German",
          "French With Italian",
          "French With Russian",
          "French With Spanish",
          "German Lang, Lit & Cult",
          "Italian Lang, Lit & Cult",
          "Latin Amcn Lang, Lit & Cult",
          "Portuguese Lang, Lit & Cult",
          "Russian Lang, Lit & Cult",
          "Russian Language & Studies",
          "Russian With German",
          "Scandinavian Lang, Lit & Cult",
          "Spanish Lang, Lit & Cult",
          # R9
          "Other Modern Language",
          # T1
          "Czech",
          # T2
          "Dutch",
          "Modern and Community Langs",
          "Modern Greek",
          "Modern Languages",
          # T4
          "Japanese",
          # T5
          "Asian Languages",
          "Gujarati",
          "Urdu",
          # T6
          "Arabic",
          "Turkish",
          # T7
          "Afrikaans",
          # T8
          "Gen Asian Lang, Lit & Cult",
          "Gen Euro Lang, Lit & Cult",
          "Gen Modern Languages",
          "General Language Studies",
          "Japanese Lang, Lit & Cult",
          # Z0
          "Spanish (And Studies)",
          "Welsh and Other Celtic Lang",
          # ZZ
          "Austrian",
          "Bengali",
          "Chinese",
          "Hindi",
          "Icelandic",
          "Modern Hebrew",
          "Punjabi"
        ],
        mathematics: [
          # G1
          "Mathematics",
          "Applied Mathematics",
          "Mathematical Education",
          "Mathematical Science",
          "Mathematical Studies",
          "Maths.Science and Technology",
          "Pure Mathematics",
          # G4
          "Statistics",
          "Operational Rsearch Techniques",
          # G5
          "Technological Mathematics",
          "Mathematics & Computer Studies",
          "Maths.Stats. and Computing",
          # G9
          "Mathematics and Science",
          "Maths and Info. Technology",
          "Maths With Computer Science",
          "Numeracy",
          "Technology and Mathematics"
        ],
        physics: [
          # F3
          "Applied Physics",
          "Chemical Physics",
          "Mathematical Physics",
          "Mechanics",
          "Natural Philosophy",
          "Physics",
          "Physics with Maths",
          "Science-Physics-Bath Ude",
          "Theoretical Physics",
          # F6
          "Physics With Technology",
          "Physics/Engineering Science",
          # F9
          "Physics (With Science)",
          "Physics and Science",
          "Physics With Core Science"
        ]
      }.freeze

      ELIGIBLE_HECOS_NAMES = {
        chemistry: [
          "chemistry",
          "applied chemistry"
        ],
        foreign_languages: [
          "French language",
          "German language",
          "Italian language",
          "modern languages",
          "Russian languages",
          "Spanish language",
          "Welsh language",
          "Portuguese language",
          "Latin language"
        ],
        mathematics: %w[
          mathematics
        ],
        physics: [
          "physics",
          "applied physics"
        ]
      }.freeze

      ELIGIBLE_ITT_SUBJECTS = {
        chemistry: [
          "applied chemistry",
          "chemistry",
          "Applied Chemistry",
          "Applied Chemistry",
          "Chemical Sciences",
          "Chemical Technology",
          "Chemistry",
          "Environmental Chemistry",
          "Inorganic Chemistry",
          "Science With Chemistry",
          "Science-Chemistry-Bath Ude"
        ],
        foreign_languages: [
          "French language",
          "German language",
          "Italian language",
          "Latin language",
          "modern languages",
          "Portuguese language",
          "Russian languages",
          "Spanish language",
          "Welsh language",
          "Modern Foreign Languages",
          "Afrikaans",
          "Ancient Greek",
          "Ancient Greek Lang & Lit",
          "Ancient language studies not elsewhere classified",
          "Arabic",
          "Asian Languages",
          "Austrian",
          "Bengali",
          "Celtic Languages",
          "Chinese",
          "Classical Greek Language",
          "Classical Languages",
          "Czech",
          "Danish",
          "Dutch",
          "Foreign & Community Languages",
          "Foreign Languages",
          "French",
          "French and German",
          "French and Spanish",
          "French Lang and Literature",
          "French Lang, Lit & Cult",
          "French Language & Studies",
          "French Literature",
          "French Studies (In Translation)",
          "French With German",
          "French With Italian",
          "French With Russian",
          "French With Spanish",
          "Frenchlang and Contemp Studs",
          "Gaelic",
          "Gen Asian Lang, Lit & Cult",
          "Gen Euro Lang, Lit & Cult",
          "Gen Modern Languages",
          "General Language Studies",
          "German",
          "German Lang, Lit & Cult",
          "German Language & Studies",
          "German Literature",
          "German With French",
          "Greek (Classical)",
          "Gujarati",
          "Hindi",
          "Hispanic",
          "Hispanic Studies",
          "Icelandic",
          "Irish",
          "Italian",
          "Italian Lang, Lit & Cult",
          "Italian Language & Studies",
          "Japanese",
          "Japanese Lang, Lit & Cult",
          "Latin",
          "Latin Amcn Lang, Lit & Cult",
          "Latin American Languages",
          "Latin Language",
          "Ling,lit & Cult Herit-Welsh",
          "Mfl(French, Spanish, German)",
          "Modern and Community Langs",
          "Modern Greek",
          "Modern Hebrew",
          "Modern Languages",
          "Norwegian",
          "Other Modern Language",
          "Portuguese",
          "Portuguese",
          "Portuguese Lang, Lit & Cult",
          "Punjabi",
          "Russian",
          "Russian Lang, Lit & Cult",
          "Russian Language & Studies",
          "Russian With German",
          "Scandinavian Lang, Lit & Cult",
          "Spanish",
          "Spanish (And Studies)",
          "Spanish Lang, Lit & Cult",
          "Spanish Language & Studies",
          "Spanish Studies (In Translation)",
          "Spanish With French",
          "Swedish",
          "Teach Eng -Speakers Other Lang",
          "Turkish",
          "Urdu",
          "Welsh",
          "Welsh and Drama",
          "Welsh and Other Celtic Lang",
          "Welsh and Welsh Studies",
          "Welsh As A Modern Language",
          "Welsh As A Second Language",
          "Welsh Literature",
          "Welsh Studies"
        ],
        mathematics: [
          "mathematics",
          "Mathematics",
          "Applied Mathematics",
          "Mathematical Education",
          "Mathematical Engineering",
          "Mathematical Science",
          "Mathematical Studies",
          "Mathematics & Computer Studies",
          "Mathematics and Science",
          "Maths and Info. Technology",
          "Maths With Computer Science",
          "Maths.Science and Technology",
          "Maths.Stats. and Computing",
          "Mechanics",
          "Numeracy",
          "Operational Rsearch Techniques",
          "Pure Mathematics",
          "Science With Mathematics",
          "Statistics",
          "Technological Mathematics",
          "Technology and Mathematics"
        ],
        physics: [
          "applied physics",
          "physics",
          "Applied Physics",
          "Chemical Physics",
          "Mathematical Physics",
          "Natural Philosophy",
          "Physics",
          "Physics (With Science)",
          "Physics and Science",
          "Physics With Core Science",
          "Physics with Maths",
          "Physics With Technology",
          "Physics/Engineering Science",
          "Science With Physics",
          "Science-Physics-Bath Ude",
          "Theoretical Physics"
        ]
      }.freeze
    end
  end
end
