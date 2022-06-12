declare module '../../res/*.conf' {
    const data: string;
    export default data;
}

declare module '../../res/*' {
    const data: Record<string, string>;
    export default data;
}
