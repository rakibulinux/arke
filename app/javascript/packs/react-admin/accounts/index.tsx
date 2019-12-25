import * as React from 'react';
import {
  Create,
  Edit,
  SimpleForm,
  ReferenceInput,
  Toolbar,
  SaveButton,
} from 'react-admin';
import { makeStyles } from '@material-ui/core/styles';
import { CardHeader } from '@material-ui/core';

import {
  StyledSelectInput as SelectInput,
  StyledTextInput as TextInput,
  StyledNumberInput as NumberInput,
} from '../partials';


const useToolbarStyles = makeStyles({
  toolbar: {
    display: 'flex',
    justifyContent: 'space-between',
    backgroundColor: 'inherit',
    marginTop: '0px',
    padding: '0 16px',
  }
});

const useButtonStyles = makeStyles({
  button: {
    width: '100%',
    padding: '8px 0px'
  }
});

const AccountToolbar = props => (
  <Toolbar {...props} classes={useToolbarStyles(props)}>
    <SaveButton
      classes={useButtonStyles(props)}
      icon={<React.Fragment />}
      label='SAVE'
    />
  </Toolbar>
);

const AccountForm = props => (
  <React.Fragment>
    {props.title &&  <CardHeader title={props.title} />}
    <SimpleForm {...props} margin='dense' toolbar={<AccountToolbar />}>

      <TextInput source='name' label='Name' />
      <ReferenceInput source='exchange_id' reference='exchanges' label='Driver'>
        <SelectInput optionText='name' variant='standard' />
      </ReferenceInput>
      <TextInput source='api_url' label='API base URL' />
      <TextInput source='ws_url' label='Websocket API base URL' />
      <NumberInput source='delay' />
      <TextInput source='api_key' />
      <TextInput source='api_secret' />
    </SimpleForm>
  </React.Fragment>
);

export const AccountEdit = (props) => (
  <Edit {...props}>
    <AccountForm />
  </Edit>
);

export const AccountCreate = props => (
  <Create {...props}>
    <AccountForm title='Add new account' />
  </Create>
);
