import * as React from 'react';
import {
  Datagrid,
  NumberInput,
  SelectInput,
  TextInput,
} from 'react-admin';

export const StyledSelectInput = props => (<SelectInput {...props} variant="standard" />);

export const StyledTextInput = props => (<TextInput {...props} variant="standard" />);

export const StyledNumberInput = props => (<NumberInput {...props} variant="standard" />);

export const StyledDatagrid = props => (<Datagrid {...props} size="medium" />);
