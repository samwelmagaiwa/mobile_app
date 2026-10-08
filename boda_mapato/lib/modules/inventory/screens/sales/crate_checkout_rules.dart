/// What stops a sale from being submitted because of its crate fields.
///
/// Crates only matter when the customer did NOT bring their empties back: then
/// the depot lends them crates, and that debt must be recorded with the sale.
/// Skipping it silently (the old behaviour when no crate type was chosen) left a
/// sale that looked recorded but whose crates were never tracked.
enum CrateCheckoutProblem { noCrateTypes, chooseType, enterQuantity }

/// The first problem with the crate fields, or null when the sale may proceed.
CrateCheckoutProblem? crateCheckoutProblem({
  required bool customerBroughtCrates,
  required bool hasCrateTypes,
  required int? crateTypeId,
  required String quantityText,
}) {
  if (customerBroughtCrates) return null;
  if (!hasCrateTypes) return CrateCheckoutProblem.noCrateTypes;
  if (crateTypeId == null) return CrateCheckoutProblem.chooseType;

  final int? quantity = int.tryParse(quantityText.trim());
  if (quantity == null || quantity < 1) {
    return CrateCheckoutProblem.enterQuantity;
  }

  return null;
}

String crateCheckoutMessage(CrateCheckoutProblem problem,
    {required bool swahili}) {
  switch (problem) {
    case CrateCheckoutProblem.noCrateTypes:
      return swahili
          ? 'Hakuna aina ya crate bado. Ongeza moja kwenye Crates & Empties, au rudisha swichi kuwa "mteja ameleta makreti".'
          : 'No crate types exist yet. Add one under Crates & empties, or switch back to "customer brought crates".';
    case CrateCheckoutProblem.chooseType:
      return swahili
          ? 'Chagua aina ya crate anayodaiwa mteja'
          : 'Choose the crate type the customer owes';
    case CrateCheckoutProblem.enterQuantity:
      return swahili
          ? 'Ingiza idadi ya makreti anayodaiwa mteja'
          : 'Enter the number of crates the customer owes';
  }
}
