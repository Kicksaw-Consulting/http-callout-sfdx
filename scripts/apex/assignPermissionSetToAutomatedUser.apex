insert new PermissionSetAssignment(
  AssigneeId = [
    SELECT Id
    FROM User
    WHERE alias = 'autoproc'
  ]
  .Id,
  PermissionSetId = [
    SELECT Id
    FROM PermissionSet
    WHERE name = 'Integration_App_Retry'
  ]
  .Id
);
