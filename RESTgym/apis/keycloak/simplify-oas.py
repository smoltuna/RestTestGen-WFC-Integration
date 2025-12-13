#!/usr/bin/env python3
"""
Simplify Keycloak OpenAPI spec by breaking circular references
"""
import json
import sys

def simplify_schema(schema_name, schema, schemas):
    """Remove problematic nested references from a schema"""
    if not isinstance(schema, dict):
        return schema
    
    if 'properties' in schema:
        props = schema['properties']
        
        # Break circular references by removing nested complex objects
        if schema_name == 'GroupRepresentation':
            # Remove self-referencing subGroups
            if 'subGroups' in props:
                props['subGroups'] = {'type': 'array', 'items': {'type': 'string'}, 'description': 'Simplified: IDs only'}
        
        elif schema_name == 'PolicyRepresentation':
            # Simplify resources, scopes references
            if 'resources' in props:
                props['resources'] = {'type': 'array', 'items': {'type': 'string'}, 'description': 'Simplified: IDs only'}
            if 'scopes' in props:
                props['scopes'] = {'type': 'array', 'items': {'type': 'string'}, 'description': 'Simplified: IDs only'}
            if 'policies' in props:
                props['policies'] = {'type': 'array', 'items': {'type': 'string'}, 'description': 'Simplified: IDs only'}
                
        elif schema_name == 'ResourceRepresentation':
            # Simplify scopes, policies references
            if 'scopes' in props:
                props['scopes'] = {'type': 'array', 'items': {'type': 'string'}, 'description': 'Simplified: IDs only'}
            if 'policies' in props:
                props['policies'] = {'type': 'array', 'items': {'type': 'string'}, 'description': 'Simplified: IDs only'}
                
        elif schema_name == 'ScopeRepresentation':
            # Simplify resources, policies references
            if 'resources' in props:
                props['resources'] = {'type': 'array', 'items': {'type': 'string'}, 'description': 'Simplified: IDs only'}
            if 'policies' in props:
                props['policies'] = {'type': 'array', 'items': {'type': 'string'}, 'description': 'Simplified: IDs only'}
                
        elif schema_name == 'ResourceServerRepresentation':
            # Simplify nested complex arrays
            if 'resources' in props:
                props['resources'] = {'type': 'array', 'items': {'type': 'string'}, 'description': 'Simplified: IDs only'}
            if 'policies' in props:
                props['policies'] = {'type': 'array', 'items': {'type': 'string'}, 'description': 'Simplified: IDs only'}
            if 'scopes' in props:
                props['scopes'] = {'type': 'array', 'items': {'type': 'string'}, 'description': 'Simplified: IDs only'}
                
        # Also simplify in nested schemas referenced by applications and clients
        for prop_name in ['resourceServer', 'authorizationSettings']:
            if prop_name in props and isinstance(props[prop_name], dict):
                if '$ref' in props[prop_name]:
                    # Keep the reference but the target will be simplified
                    pass
                    
    return schema

def main():
    if len(sys.argv) < 2:
        print("Usage: python simplify-oas.py <input-openapi.json>")
        sys.exit(1)
    
    input_file = sys.argv[1]
    output_file = input_file.replace('.json', '-simplified.json')
    
    print(f"Reading {input_file}...")
    with open(input_file, 'r') as f:
        spec = json.load(f)
    
    if 'components' in spec and 'schemas' in spec['components']:
        schemas = spec['components']['schemas']
        
        print(f"Simplifying {len(schemas)} schemas...")
        for schema_name, schema in schemas.items():
            simplify_schema(schema_name, schema, schemas)
        
        print(f"Writing simplified spec to {output_file}...")
        with open(output_file, 'w') as f:
            json.dump(spec, f, indent=2)
        
        print(f"Done! Simplified spec saved to {output_file}")
    else:
        print("No schemas found in spec")
        sys.exit(1)

if __name__ == '__main__':
    main()
