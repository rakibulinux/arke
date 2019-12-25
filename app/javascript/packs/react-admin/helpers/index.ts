export const capitalize = (str: string) => (str.charAt(0).toUpperCase() + str.slice(1));

export const formOptions = (...options: string[]) => options.map(o => ({ id: o, name: capitalize(o) }))
