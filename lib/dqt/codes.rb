module Dqt
  class Codes
    QUALIFICATION_MATCHING_TYPE = {
      post: [
        nil,
        "Degree",
        "Degree Equivalent (this will include foreign qualifications)",
        "Flexible - PGCE",
        "Flexible - ProfGCE",
        "Graduate Certificate in Education",
        "Graduate Diploma",
        "GTP",
        "Masters, not by research",
        "Postgraduate Certificate in Education",
        "Postgraduate Certificate in Education (Flexible)",
        "Postgraduate Diploma in Education",
        "Professional Graduate Certificate in Education",
        "Professional Graduate Diploma in Education",
        "Teach First",
        "Teach First (TNP)",
        "Teachers Certificate",
        "Unknown"
      ],
      under: [
        "BA",
        "BA (Hons)",
        "BA (Hons) Combined Studies/Education of the Deaf",
        "BA/Education (QTS)",
        "BEd",
        "BEd (Hons)",
        "BSc",
        "BSc (Hons)",
        "BSc (Hons) with Intercalated PGCE",
        "BSc/Education (QTS)",
        "Undergraduate Master of Teaching"
      ],
      other: [
        "EEA",
        "Northern Ireland",
        "OTT",
        "OTT Recognition",
        "QTS Assessment only",
        "QTS Award only",
        "Scotland"
      ]
    }.freeze
  end
end
