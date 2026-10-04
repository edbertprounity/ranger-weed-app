enum AppRole { admin, ranger, public }

AppRole? roleFromName(String? value) {
  return switch (value) {
    'admin' => AppRole.admin,
    'ranger' => AppRole.ranger,
    'public' => AppRole.public,
    _ => null,
  };
}

String roleLabel(AppRole role) {
  return switch (role) {
    AppRole.admin => 'Admin',
    AppRole.ranger => 'Ranger',
    AppRole.public => 'Public',
  };
}
