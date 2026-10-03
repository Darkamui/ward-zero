extends TestCase


func after_each() -> void:
	TranslationServer.set_locale("en")


func test_both_locales_loaded() -> void:
	TranslationServer.set_locale("en")
	assert_eq(tr("ui.title"), "Ward Zero")
	TranslationServer.set_locale("fr_CA")
	assert_eq(tr("ui.title"), "Aile Zéro")


func test_placeholder_format() -> void:
	TranslationServer.set_locale("fr_CA")
	assert_eq(tr("ui.test.greeting").format({"name": "Mathieu"}), "Bonjour, Mathieu.")


func test_fr_falls_back_from_plain_fr() -> void:
	TranslationServer.set_locale("fr")
	assert_eq(tr("ui.title"), "Aile Zéro", "fr should resolve to fr_CA")
