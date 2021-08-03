package test;

final TestSubQueries = suite(test -> {

  test('IncludeMany', () -> {
    final db = new Store();
    final Role = new Collection<{id: String, name: String}>('Role');
    final role1 = db.insert(Role, {name: 'role1'});
    final role2 = db.insert(Role, {name: 'role2'});
    final User = new Collection<{id: String, roles: Array<String>}>('User');
    final user = db.insert(User, {roles: [role1.id, role2.id]});
    final UserAlias = User.as('user1');
    final RoleAlias = Role.as('role');
    final bundled = db.first(
      UserAlias.select(
        UserAlias.fields.with({
          roles: RoleAlias.where(RoleAlias.id.isIn(UserAlias.roles)).select({
            name: RoleAlias.name
          }).orderBy([RoleAlias.name.asc()])
        })
      )
    );
    assert.equal( 
      [{name: 'role1'}, {name: 'role2'}],
      bundled.roles
    );
    final Entry = new Collection<{id: String}>('Entry');
    final Language = new Collection<{id: String, entry: String}>('Language');
    final Version = new Collection<{id: String, language: String}>('Version');
    final entry = db.insert(Entry, {});
    final language = db.insert(Language, {entry: entry.id});
    final version1 = db.insert(Version, {
      language: language.id
    });
    final version2 = db.insert(Version, {
      language: language.id
    });
    final page = db.first(
      Entry.select(
        Entry.fields.with({
          languages: Language.where(Language.entry.is(Entry.id)).select(
            Language.fields.with({
              versions: Version.where(Version.language.is(Language.id))
            })
          )
        })
      )
    );
    assert.equal(merge(entry, {
      languages: [
        merge(language, {
          versions: [version1, version2]
        })
      ]
    }), page);
  });
  
  test('Subquery', () -> {
    final store = new Store();
    final User = new Collection<{id: String, name: String}>('user');
    final Post = new Collection<{id: String, title: String, user: String}>('post');
    final user1 = store.insert(User, {name: 'bob'});
    final post1 = store.insert(Post, {title: 'hello', user: user1.id});
    final userWithPosts = store.first(
      User.where(User.id == user1.id).select(
        User.fields.with({
          posts: Post.where(Post.user == User.id).select({
            id: Post.id
          })
        })
      )
    );
    assert.is(userWithPosts.name, 'bob');
    assert.is(userWithPosts.posts[0].id, post1.id);
  });

});