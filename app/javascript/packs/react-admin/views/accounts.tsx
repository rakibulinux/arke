import * as React from 'react';
import {
  Create,
  Datagrid,
  DateField,
  Edit,
  EmailField,
  Filter,
  List,
  NumberInput,
  NumberField,
  SimpleForm,
  SimpleShowLayout,
  Show,
  SelectInput,
  TextField,
  TextInput,
  ReferenceField,
  ReferenceInput,
} from 'react-admin';

export const AccountList = props => (
  <List {...props}>
      <Datagrid rowClick="edit">
          <TextField source="id" />
          <ReferenceField source="exchange_id" reference="exchanges">
            <TextField source="id" />
          </ReferenceField>
          <TextField source="name" />
          <DateField source="created_at" />
          <DateField source="updated_at" />
          <TextField source="api_key" />
          <TextField source="api_secret" />
      </Datagrid>
  </List>
);

const AccountForm = props => (
  <SimpleForm>
    <TextInput source="id" />
    <ReferenceInput source="exchange_id" reference="exchanges">
      <SelectInput optionText="id" />
    </ReferenceInput>
    <TextInput source="name" />
    <TextInput source="api_key" />
    <TextInput source="api_secret" />
  </SimpleForm>
);

export const AccountEdit = props => (
  <Edit {...props}>
    <AccountForm />
  </Edit>
);

export const AccountCreate = props => (
  <Create {...props}>
    <AccountForm />
  </Create>
);

export const AccountShow = props => (
  <Show title="Account" {...props}>
    <SimpleShowLayout>
      <TextField source="uid" />
      <TextField source="email" />
      <NumberField source="level" />
      <TextField source="role" />
      <TextField source="state" />
    </SimpleShowLayout>
  </Show>
);
