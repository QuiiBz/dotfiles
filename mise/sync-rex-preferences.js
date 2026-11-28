ObjC.import('Foundation');

function run([preferencesPath]) {
  const savedPreferences = $.NSDictionary.dictionaryWithContentsOfFile(preferencesPath);
  if (savedPreferences.isNil() || savedPreferences.count === 0) {
    throw new Error(`Could not read Rex preferences at ${preferencesPath}`);
  }

  const rexPreferences = $.NSUserDefaults.alloc.initWithSuiteName('com.superlogical.rex');
  for (const key of ObjC.unwrap(savedPreferences.allKeys)) {
    rexPreferences.setObjectForKey(savedPreferences.objectForKey(key), key);
  }

  if (!rexPreferences.synchronize) {
    throw new Error('Could not save Rex preferences');
  }
}
