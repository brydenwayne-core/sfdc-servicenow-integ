#!/usr/bin/env python3
from __future__ import annotations
import sys
import xml.etree.ElementTree as ET
from collections import defaultdict
from datetime import date
from pathlib import Path

NS = {'m': 'http://soap.sforce.com/2006/04/metadata'}
ROOT = Path(__file__).resolve().parents[2]
CUSTOM_METADATA_DIR = ROOT / 'force-app' / 'sample-config' / 'main' / 'default' / 'customMetadata'

class Record:
    def __init__(self, path: Path):
        self.path = path
        self.type_name = path.name.split('.', 1)[0]
        tree = ET.parse(path)
        root = tree.getroot()
        self.label = root.findtext('m:label', default='', namespaces=NS)
        self.values = {}
        for node in root.findall('m:values', NS):
            field = node.findtext('m:field', default='', namespaces=NS)
            value_el = node.find('m:value', NS)
            self.values[field] = '' if value_el is None or value_el.text is None else value_el.text.strip()

    def get(self, field: str, default: str = '') -> str:
        return self.values.get(field, default)

    def active(self) -> bool:
        return self.get('Is_Active__c', 'false').lower() == 'true'

records = [Record(path) for path in sorted(CUSTOM_METADATA_DIR.glob('*.md-meta.xml')) if path.name != '.gitkeep']
by_type = defaultdict(list)
for record in records:
    by_type[record.type_name].append(record)

errors: list[str] = []
warnings: list[str] = []

def key_index(type_name: str, field_name: str):
    index = {}
    for record in by_type[type_name]:
        key = record.get(field_name)
        if key:
            index[(record.get('Org_Key__c', 'GLOBAL'), key)] = record
            index[('GLOBAL', key)] = record if record.get('Org_Key__c') in ('', 'GLOBAL') else index.get(('GLOBAL', key), None) or None
    return index

request_types = {(r.get('Org_Key__c'), r.get('Request_Type_Key__c')): r for r in by_type['SN_Request_Type']}
assignment_targets = {(r.get('Org_Key__c'), r.get('Assignment_Target_Key__c')): r for r in by_type['SN_Assignment_Target']}
incident_templates = {(r.get('Org_Key__c'), r.get('Incident_Template_Key__c')): r for r in by_type['SN_Incident_Template']}
endpoint_configs = {(r.get('Org_Key__c', 'GLOBAL'), r.get('Endpoint_Config_Key__c')): r for r in by_type['SN_Endpoint_Config']}

for record in records:
    start = record.get('Effective_Start_Date__c')
    end = record.get('Effective_End_Date__c')
    if start and end and start > end:
        errors.append(f'{record.path.name}: Effective_Start_Date__c must be on or before Effective_End_Date__c')
    lifecycle = record.get('Lifecycle_Status__c')
    if record.active() and lifecycle in {'Deprecated', 'Retired'}:
        warnings.append(f'{record.path.name}: active record uses lifecycle status {lifecycle}')
    if record.get('Documentation_URL__c') == '':
        warnings.append(f'{record.path.name}: missing Documentation_URL__c')

for org_record in by_type['SN_Org_Config']:
    org_key = org_record.get('Org_Key__c')
    default_request = org_record.get('Default_Request_Type__c')
    endpoint = org_record.get('Endpoint_Config_Key__c')
    if default_request and (org_key, default_request) not in request_types:
        errors.append(f'{org_record.path.name}: Default_Request_Type__c references missing request type {default_request}')
    if endpoint and ('GLOBAL', endpoint) not in endpoint_configs and (org_key, endpoint) not in endpoint_configs:
        errors.append(f'{org_record.path.name}: Endpoint_Config_Key__c references missing endpoint config {endpoint}')

routing_defaults = defaultdict(list)
for route in by_type['SN_Routing_Rule']:
    org_key = route.get('Org_Key__c')
    request_type = route.get('Request_Type_Key__c')
    assign_key = route.get('Assignment_Target_Key__c')
    if request_type and (org_key, request_type) not in request_types:
        errors.append(f'{route.path.name}: Request_Type_Key__c references missing request type {request_type}')
    if assign_key and (org_key, assign_key) not in assignment_targets:
        errors.append(f'{route.path.name}: Assignment_Target_Key__c references missing assignment target {assign_key}')
    if route.get('Is_Default__c', 'false').lower() == 'true' and route.active():
        routing_defaults[(org_key, request_type)].append(route)

for key, matches in routing_defaults.items():
    if len(matches) > 1:
        errors.append(f'Routing defaults conflict for org/request {key}: {", ".join(r.path.name for r in matches)}')

for req in by_type['SN_Request_Type']:
    org_key = req.get('Org_Key__c')
    template_key = req.get('Incident_Template_Key__c')
    if template_key and (org_key, template_key) not in incident_templates:
        errors.append(f'{req.path.name}: Incident_Template_Key__c references missing incident template {template_key}')
    if req.active() and not routing_defaults.get((org_key, req.get('Request_Type_Key__c'))):
        warnings.append(f'{req.path.name}: active request type has no active fallback routing rule')

mappings_by_scope = defaultdict(list)
for mapping in by_type['SN_Field_Mapping']:
    org_key = mapping.get('Org_Key__c')
    request_type = mapping.get('Request_Type_Key__c')
    if request_type and (org_key, request_type) not in request_types:
        errors.append(f'{mapping.path.name}: Request_Type_Key__c references missing request type {request_type}')
    sequence = mapping.get('Sequence__c')
    if sequence:
        mappings_by_scope[(org_key, request_type, sequence)].append(mapping)

for key, matches in mappings_by_scope.items():
    if len(matches) > 1:
        warnings.append(f'Duplicate field mapping execution order for scope {key}: {", ".join(r.path.name for r in matches)}')

for feature in by_type['SN_Feature_Toggle']:
    org_key = feature.get('Org_Key__c')
    if not org_key:
        warnings.append(f'{feature.path.name}: Feature toggle should use GLOBAL or an explicit Org_Key__c')

if warnings:
    print('Warnings:')
    for item in warnings:
        print(f' - {item}')
if errors:
    print('Errors:')
    for item in errors:
        print(f' - {item}')
    sys.exit(1)
print(f'Validated {len(records)} custom metadata records successfully.')
