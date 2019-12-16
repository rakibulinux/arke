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
  CreateButton,
  CardActions,
  ExportButton,
} from 'react-admin';
import { Drawer, Toolbar } from '@material-ui/core';
import { Route } from 'react-router';

const AccountForm = props => (
  <SimpleForm {...props}>
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
