Pod::Spec.new do |spec|
  spec.name = "DollarGestureRecognizer"
  spec.version = "1.0.0"
  spec.summary = "Implements the dollar recognizers in swift and expose them as a set of custom UIGestureRecognizer subclasses."
  spec.homepage = "https://github.com/DanielCardonaRojas/DollarGestureRecognizer"
  spec.license = { type: 'MIT', file: 'LICENSE' }
  spec.authors = { "Daniel Cardona Rojas" => 'd.cardona.rojas@gmail.com' }
  spec.swift_version = "5.0"
  spec.platform = :ios, "12.0"
  spec.requires_arc = true
  spec.source = { git: "https://github.com/DanielCardonaRojas/DollarGestureRecognizer.git", tag: "v#{spec.version}" }
  spec.source_files = "DollarGestureRecognizer/**/*.{h,swift}"
end
