// Lean compiler output
// Module: Vsr.Smoke
// Imports: public import Init public meta import Init public import Veil
#include <lean/lean.h>
#if defined(__clang__)
#pragma clang diagnostic ignored "-Wunused-parameter"
#pragma clang diagnostic ignored "-Wunused-label"
#elif defined(__GNUC__) && !defined(__CLANG__)
#pragma GCC diagnostic ignored "-Wunused-parameter"
#pragma GCC diagnostic ignored "-Wunused-label"
#pragma GCC diagnostic ignored "-Wunused-but-set-variable"
#endif
#ifdef __cplusplus
extern "C" {
#endif
lean_object* l_Lean_mkAtom(lean_object*);
lean_object* lean_mk_empty_array_with_capacity(lean_object*);
lean_object* lean_array_push(lean_object*, lean_object*);
lean_object* lp_veil_Veil_canonicalFieldRepresentation___redArg(lean_object*, lean_object*);
lean_object* l_Lean_Name_mkStr1(lean_object*);
lean_object* lean_mk_empty_array_with_capacity(lean_object*);
lean_object* l_Lean_Syntax_getId(lean_object*);
uint8_t lp_auto_Array_contains___at___00Auto_Deriving_ToExpr_mkInstanceCmds_spec__0(lean_object*, lean_object*);
uint8_t lp_veil_Veil_isCapital(lean_object*);
uint8_t lp_veil_List_any___at___00Veil_isVeilProcedureContext_spec__0(lean_object*);
lean_object* l_Repr_addAppParen(lean_object*, lean_object*);
uint8_t lean_nat_dec_le(lean_object*, lean_object*);
lean_object* lean_nat_to_int(lean_object*);
uint64_t lean_uint64_mix_hash(uint64_t, uint64_t);
lean_object* l_Lean_Name_mkStr2(lean_object*, lean_object*);
lean_object* lean_string_length(lean_object*);
lean_object* lp_Loom_NonDetT_bind___redArg(lean_object*, lean_object*);
lean_object* l_Std_Format_pretty(lean_object*, lean_object*, lean_object*, lean_object*);
lean_object* lp_veil_Veil_VeilM_require___redArg(uint8_t, uint8_t, lean_object*);
lean_object* lp_veil_Veil_VeilM_returnUnit___redArg(lean_object*);
lean_object* l_Lean_Json_mkObj(lean_object*);
lean_object* l_Lean_Name_mkStr4(lean_object*, lean_object*, lean_object*, lean_object*);
lean_object* l_Std_Format_joinSep___redArg(lean_object*, lean_object*, lean_object*);
lean_object* l_Std_instToFormatFormat___lam__0___boxed(lean_object*);
lean_object* lp_veil_Veil_instFinmapLikeBoolExtTreeSetOfTransCmp___redArg(lean_object*);
lean_object* lp_veil_Veil_IteratedProd_x27_equiv(lean_object*);
lean_object* lp_veil_Veil_instFinmapLikeAsFieldRep___redArg(lean_object*, lean_object*, lean_object*, lean_object*);
lean_object* l_List_get___redArg(lean_object*, lean_object*);
lean_object* lp_veil_Veil_IteratedProd_foldMap___redArg(lean_object*, lean_object*, lean_object*, lean_object*);
lean_object* l_List_lengthTR___redArg(lean_object*);
lean_object* lp_veil_Veil_Ord_ofFinEncodable___redArg___lam__0___boxed(lean_object*, lean_object*, lean_object*);
lean_object* l_List_mapTR_loop___redArg(lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_State_Label_toCtorIdx(lean_object*);
static const lean_ctor_object lp_vsr_x2dveil_Smoke_State_Label_toDomain___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(0) << 1) | 1)),((lean_object*)(((size_t)(0) << 1) | 1))}};
static const lean_object* lp_vsr_x2dveil_Smoke_State_Label_toDomain___closed__0 = (const lean_object*)&lp_vsr_x2dveil_Smoke_State_Label_toDomain___closed__0_value;
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_State_Label_toDomain(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instEnumerationForIteratedProd___redArg(lean_object*);
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instEnumerationForIteratedProd(lean_object*, lean_object*, lean_object*);
LEAN_EXPORT uint8_t lp_vsr_x2dveil_Smoke_instEnumerationForIteratedProdAllSomeCheck(lean_object*);
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instEnumerationForIteratedProdAllSomeCheck___boxed(lean_object*);
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instInhabitedStateFieldConcreteType___redArg(lean_object*);
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instInhabitedStateFieldConcreteType___redArg___boxed(lean_object*);
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instInhabitedStateFieldConcreteType(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instInhabitedStateFieldConcreteType___boxed(lean_object*, lean_object*);
LEAN_EXPORT uint64_t lp_vsr_x2dveil_Smoke_instHashableStateOfLeader___redArg___lam__0(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instHashableStateOfLeader___redArg___lam__0___boxed(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instHashableStateOfLeader___redArg(lean_object*);
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instHashableStateOfLeader(lean_object*, lean_object*);
LEAN_EXPORT uint8_t lp_vsr_x2dveil_Smoke_instBEqStateOfLeader___redArg___lam__0(lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instBEqStateOfLeader___redArg___lam__0___boxed(lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instBEqStateOfLeader___redArg(lean_object*);
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instBEqStateOfLeader(lean_object*, lean_object*);
LEAN_EXPORT uint8_t lp_vsr_x2dveil_Smoke_instDecidableEqStateOfLeader___redArg(lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instDecidableEqStateOfLeader___redArg___boxed(lean_object*, lean_object*, lean_object*);
LEAN_EXPORT uint8_t lp_vsr_x2dveil_Smoke_instDecidableEqStateOfLeader(lean_object*, lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instDecidableEqStateOfLeader___boxed(lean_object*, lean_object*, lean_object*, lean_object*);
static const lean_string_object lp_vsr_x2dveil_Smoke_instToJsonStateOfLeader___redArg___lam__0___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 7, .m_capacity = 7, .m_length = 6, .m_data = "leader"};
static const lean_object* lp_vsr_x2dveil_Smoke_instToJsonStateOfLeader___redArg___lam__0___closed__0 = (const lean_object*)&lp_vsr_x2dveil_Smoke_instToJsonStateOfLeader___redArg___lam__0___closed__0_value;
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instToJsonStateOfLeader___redArg___lam__0(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instToJsonStateOfLeader___redArg(lean_object*);
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instToJsonStateOfLeader(lean_object*, lean_object*);
static const lean_string_object lp_vsr_x2dveil_Smoke_instReprStateOfLeader___redArg___lam__0___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 3, .m_capacity = 3, .m_length = 2, .m_data = "{ "};
static const lean_object* lp_vsr_x2dveil_Smoke_instReprStateOfLeader___redArg___lam__0___closed__0 = (const lean_object*)&lp_vsr_x2dveil_Smoke_instReprStateOfLeader___redArg___lam__0___closed__0_value;
static const lean_string_object lp_vsr_x2dveil_Smoke_instReprStateOfLeader___redArg___lam__0___closed__1_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 11, .m_capacity = 11, .m_length = 10, .m_data = "leader := "};
static const lean_object* lp_vsr_x2dveil_Smoke_instReprStateOfLeader___redArg___lam__0___closed__1 = (const lean_object*)&lp_vsr_x2dveil_Smoke_instReprStateOfLeader___redArg___lam__0___closed__1_value;
static const lean_ctor_object lp_vsr_x2dveil_Smoke_instReprStateOfLeader___redArg___lam__0___closed__2_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*1 + 0, .m_other = 1, .m_tag = 3}, .m_objs = {((lean_object*)&lp_vsr_x2dveil_Smoke_instReprStateOfLeader___redArg___lam__0___closed__1_value)}};
static const lean_object* lp_vsr_x2dveil_Smoke_instReprStateOfLeader___redArg___lam__0___closed__2 = (const lean_object*)&lp_vsr_x2dveil_Smoke_instReprStateOfLeader___redArg___lam__0___closed__2_value;
static const lean_string_object lp_vsr_x2dveil_Smoke_instReprStateOfLeader___redArg___lam__0___closed__3_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 3, .m_capacity = 3, .m_length = 2, .m_data = ", "};
static const lean_object* lp_vsr_x2dveil_Smoke_instReprStateOfLeader___redArg___lam__0___closed__3 = (const lean_object*)&lp_vsr_x2dveil_Smoke_instReprStateOfLeader___redArg___lam__0___closed__3_value;
static const lean_ctor_object lp_vsr_x2dveil_Smoke_instReprStateOfLeader___redArg___lam__0___closed__4_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*1 + 0, .m_other = 1, .m_tag = 3}, .m_objs = {((lean_object*)&lp_vsr_x2dveil_Smoke_instReprStateOfLeader___redArg___lam__0___closed__3_value)}};
static const lean_object* lp_vsr_x2dveil_Smoke_instReprStateOfLeader___redArg___lam__0___closed__4 = (const lean_object*)&lp_vsr_x2dveil_Smoke_instReprStateOfLeader___redArg___lam__0___closed__4_value;
static const lean_string_object lp_vsr_x2dveil_Smoke_instReprStateOfLeader___redArg___lam__0___closed__5_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 3, .m_capacity = 3, .m_length = 2, .m_data = " }"};
static const lean_object* lp_vsr_x2dveil_Smoke_instReprStateOfLeader___redArg___lam__0___closed__5 = (const lean_object*)&lp_vsr_x2dveil_Smoke_instReprStateOfLeader___redArg___lam__0___closed__5_value;
static lean_once_cell_t lp_vsr_x2dveil_Smoke_instReprStateOfLeader___redArg___lam__0___closed__6_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_vsr_x2dveil_Smoke_instReprStateOfLeader___redArg___lam__0___closed__6;
static lean_once_cell_t lp_vsr_x2dveil_Smoke_instReprStateOfLeader___redArg___lam__0___closed__7_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_vsr_x2dveil_Smoke_instReprStateOfLeader___redArg___lam__0___closed__7;
static const lean_ctor_object lp_vsr_x2dveil_Smoke_instReprStateOfLeader___redArg___lam__0___closed__8_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*1 + 0, .m_other = 1, .m_tag = 3}, .m_objs = {((lean_object*)&lp_vsr_x2dveil_Smoke_instReprStateOfLeader___redArg___lam__0___closed__0_value)}};
static const lean_object* lp_vsr_x2dveil_Smoke_instReprStateOfLeader___redArg___lam__0___closed__8 = (const lean_object*)&lp_vsr_x2dveil_Smoke_instReprStateOfLeader___redArg___lam__0___closed__8_value;
static const lean_ctor_object lp_vsr_x2dveil_Smoke_instReprStateOfLeader___redArg___lam__0___closed__9_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*1 + 0, .m_other = 1, .m_tag = 3}, .m_objs = {((lean_object*)&lp_vsr_x2dveil_Smoke_instReprStateOfLeader___redArg___lam__0___closed__5_value)}};
static const lean_object* lp_vsr_x2dveil_Smoke_instReprStateOfLeader___redArg___lam__0___closed__9 = (const lean_object*)&lp_vsr_x2dveil_Smoke_instReprStateOfLeader___redArg___lam__0___closed__9_value;
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instReprStateOfLeader___redArg___lam__0(lean_object*, lean_object*, lean_object*, lean_object*);
static const lean_closure_object lp_vsr_x2dveil_Smoke_instReprStateOfLeader___redArg___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_closure_object) + sizeof(void*)*0, .m_other = 0, .m_tag = 245}, .m_fun = (void*)l_Std_instToFormatFormat___lam__0___boxed, .m_arity = 1, .m_num_fixed = 0, .m_objs = {} };
static const lean_object* lp_vsr_x2dveil_Smoke_instReprStateOfLeader___redArg___closed__0 = (const lean_object*)&lp_vsr_x2dveil_Smoke_instReprStateOfLeader___redArg___closed__0_value;
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instReprStateOfLeader___redArg(lean_object*);
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instReprStateOfLeader(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_State__ho(lean_object*);
static lean_once_cell_t lp_vsr_x2dveil_Smoke_instFieldRepresentation___redArg___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_vsr_x2dveil_Smoke_instFieldRepresentation___redArg___closed__0;
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instFieldRepresentation___redArg(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instFieldRepresentation(lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instFieldRepresentation___boxed(lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instAbstractFieldRepresentation___redArg(lean_object*);
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instAbstractFieldRepresentation(lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instEnumerationStateOfLeader___redArg___lam__0(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instEnumerationStateOfLeader___redArg___lam__1(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instEnumerationStateOfLeader___redArg___lam__1___boxed(lean_object*, lean_object*);
static const lean_closure_object lp_vsr_x2dveil_Smoke_instEnumerationStateOfLeader___redArg___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_closure_object) + sizeof(void*)*0, .m_other = 0, .m_tag = 245}, .m_fun = (void*)lp_vsr_x2dveil_Smoke_instEnumerationStateOfLeader___redArg___lam__0, .m_arity = 2, .m_num_fixed = 0, .m_objs = {} };
static const lean_object* lp_vsr_x2dveil_Smoke_instEnumerationStateOfLeader___redArg___closed__0 = (const lean_object*)&lp_vsr_x2dveil_Smoke_instEnumerationStateOfLeader___redArg___closed__0_value;
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instEnumerationStateOfLeader___redArg(lean_object*);
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instEnumerationStateOfLeader(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instInhabitedTheory_default(lean_object*);
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instInhabitedTheory(lean_object*);
static const lean_string_object lp_vsr_x2dveil_Smoke_instReprTheory___lam__0___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 1, .m_capacity = 1, .m_length = 0, .m_data = ""};
static const lean_object* lp_vsr_x2dveil_Smoke_instReprTheory___lam__0___closed__0 = (const lean_object*)&lp_vsr_x2dveil_Smoke_instReprTheory___lam__0___closed__0_value;
static const lean_ctor_object lp_vsr_x2dveil_Smoke_instReprTheory___lam__0___closed__1_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*1 + 0, .m_other = 1, .m_tag = 3}, .m_objs = {((lean_object*)&lp_vsr_x2dveil_Smoke_instReprTheory___lam__0___closed__0_value)}};
static const lean_object* lp_vsr_x2dveil_Smoke_instReprTheory___lam__0___closed__1 = (const lean_object*)&lp_vsr_x2dveil_Smoke_instReprTheory___lam__0___closed__1_value;
static const lean_ctor_object lp_vsr_x2dveil_Smoke_instReprTheory___lam__0___closed__2_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 5}, .m_objs = {((lean_object*)&lp_vsr_x2dveil_Smoke_instReprStateOfLeader___redArg___lam__0___closed__8_value),((lean_object*)&lp_vsr_x2dveil_Smoke_instReprTheory___lam__0___closed__1_value)}};
static const lean_object* lp_vsr_x2dveil_Smoke_instReprTheory___lam__0___closed__2 = (const lean_object*)&lp_vsr_x2dveil_Smoke_instReprTheory___lam__0___closed__2_value;
static const lean_ctor_object lp_vsr_x2dveil_Smoke_instReprTheory___lam__0___closed__3_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 5}, .m_objs = {((lean_object*)&lp_vsr_x2dveil_Smoke_instReprTheory___lam__0___closed__2_value),((lean_object*)&lp_vsr_x2dveil_Smoke_instReprStateOfLeader___redArg___lam__0___closed__9_value)}};
static const lean_object* lp_vsr_x2dveil_Smoke_instReprTheory___lam__0___closed__3 = (const lean_object*)&lp_vsr_x2dveil_Smoke_instReprTheory___lam__0___closed__3_value;
static lean_once_cell_t lp_vsr_x2dveil_Smoke_instReprTheory___lam__0___closed__4_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_vsr_x2dveil_Smoke_instReprTheory___lam__0___closed__4;
static lean_once_cell_t lp_vsr_x2dveil_Smoke_instReprTheory___lam__0___closed__5_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_vsr_x2dveil_Smoke_instReprTheory___lam__0___closed__5;
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instReprTheory___lam__0(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instReprTheory___lam__0___boxed(lean_object*, lean_object*);
static const lean_closure_object lp_vsr_x2dveil_Smoke_instReprTheory___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_closure_object) + sizeof(void*)*0, .m_other = 0, .m_tag = 245}, .m_fun = (void*)lp_vsr_x2dveil_Smoke_instReprTheory___lam__0___boxed, .m_arity = 2, .m_num_fixed = 0, .m_objs = {} };
static const lean_object* lp_vsr_x2dveil_Smoke_instReprTheory___closed__0 = (const lean_object*)&lp_vsr_x2dveil_Smoke_instReprTheory___closed__0_value;
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instReprTheory(lean_object*);
static lean_once_cell_t lp_vsr_x2dveil_Smoke_instToJsonTheory___lam__0___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_vsr_x2dveil_Smoke_instToJsonTheory___lam__0___closed__0;
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instToJsonTheory___lam__0(lean_object*);
static const lean_closure_object lp_vsr_x2dveil_Smoke_instToJsonTheory___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_closure_object) + sizeof(void*)*0, .m_other = 0, .m_tag = 245}, .m_fun = (void*)lp_vsr_x2dveil_Smoke_instToJsonTheory___lam__0, .m_arity = 1, .m_num_fixed = 0, .m_objs = {} };
static const lean_object* lp_vsr_x2dveil_Smoke_instToJsonTheory___closed__0 = (const lean_object*)&lp_vsr_x2dveil_Smoke_instToJsonTheory___closed__0_value;
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instToJsonTheory(lean_object*);
static const lean_string_object lp_vsr_x2dveil_Smoke_instReprInstantiation_repr___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 5, .m_capacity = 5, .m_length = 4, .m_data = "node"};
static const lean_object* lp_vsr_x2dveil_Smoke_instReprInstantiation_repr___closed__0 = (const lean_object*)&lp_vsr_x2dveil_Smoke_instReprInstantiation_repr___closed__0_value;
static const lean_ctor_object lp_vsr_x2dveil_Smoke_instReprInstantiation_repr___closed__1_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*1 + 0, .m_other = 1, .m_tag = 3}, .m_objs = {((lean_object*)&lp_vsr_x2dveil_Smoke_instReprInstantiation_repr___closed__0_value)}};
static const lean_object* lp_vsr_x2dveil_Smoke_instReprInstantiation_repr___closed__1 = (const lean_object*)&lp_vsr_x2dveil_Smoke_instReprInstantiation_repr___closed__1_value;
static const lean_ctor_object lp_vsr_x2dveil_Smoke_instReprInstantiation_repr___closed__2_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 5}, .m_objs = {((lean_object*)(((size_t)(0) << 1) | 1)),((lean_object*)&lp_vsr_x2dveil_Smoke_instReprInstantiation_repr___closed__1_value)}};
static const lean_object* lp_vsr_x2dveil_Smoke_instReprInstantiation_repr___closed__2 = (const lean_object*)&lp_vsr_x2dveil_Smoke_instReprInstantiation_repr___closed__2_value;
static const lean_string_object lp_vsr_x2dveil_Smoke_instReprInstantiation_repr___closed__3_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 5, .m_capacity = 5, .m_length = 4, .m_data = " := "};
static const lean_object* lp_vsr_x2dveil_Smoke_instReprInstantiation_repr___closed__3 = (const lean_object*)&lp_vsr_x2dveil_Smoke_instReprInstantiation_repr___closed__3_value;
static const lean_ctor_object lp_vsr_x2dveil_Smoke_instReprInstantiation_repr___closed__4_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*1 + 0, .m_other = 1, .m_tag = 3}, .m_objs = {((lean_object*)&lp_vsr_x2dveil_Smoke_instReprInstantiation_repr___closed__3_value)}};
static const lean_object* lp_vsr_x2dveil_Smoke_instReprInstantiation_repr___closed__4 = (const lean_object*)&lp_vsr_x2dveil_Smoke_instReprInstantiation_repr___closed__4_value;
static const lean_ctor_object lp_vsr_x2dveil_Smoke_instReprInstantiation_repr___closed__5_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 5}, .m_objs = {((lean_object*)&lp_vsr_x2dveil_Smoke_instReprInstantiation_repr___closed__2_value),((lean_object*)&lp_vsr_x2dveil_Smoke_instReprInstantiation_repr___closed__4_value)}};
static const lean_object* lp_vsr_x2dveil_Smoke_instReprInstantiation_repr___closed__5 = (const lean_object*)&lp_vsr_x2dveil_Smoke_instReprInstantiation_repr___closed__5_value;
static const lean_string_object lp_vsr_x2dveil_Smoke_instReprInstantiation_repr___closed__6_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 2, .m_capacity = 2, .m_length = 1, .m_data = "_"};
static const lean_object* lp_vsr_x2dveil_Smoke_instReprInstantiation_repr___closed__6 = (const lean_object*)&lp_vsr_x2dveil_Smoke_instReprInstantiation_repr___closed__6_value;
static const lean_ctor_object lp_vsr_x2dveil_Smoke_instReprInstantiation_repr___closed__7_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*1 + 0, .m_other = 1, .m_tag = 3}, .m_objs = {((lean_object*)&lp_vsr_x2dveil_Smoke_instReprInstantiation_repr___closed__6_value)}};
static const lean_object* lp_vsr_x2dveil_Smoke_instReprInstantiation_repr___closed__7 = (const lean_object*)&lp_vsr_x2dveil_Smoke_instReprInstantiation_repr___closed__7_value;
static const lean_ctor_object lp_vsr_x2dveil_Smoke_instReprInstantiation_repr___closed__8_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 5}, .m_objs = {((lean_object*)&lp_vsr_x2dveil_Smoke_instReprInstantiation_repr___closed__5_value),((lean_object*)&lp_vsr_x2dveil_Smoke_instReprInstantiation_repr___closed__7_value)}};
static const lean_object* lp_vsr_x2dveil_Smoke_instReprInstantiation_repr___closed__8 = (const lean_object*)&lp_vsr_x2dveil_Smoke_instReprInstantiation_repr___closed__8_value;
static lean_once_cell_t lp_vsr_x2dveil_Smoke_instReprInstantiation_repr___closed__9_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_vsr_x2dveil_Smoke_instReprInstantiation_repr___closed__9;
static const lean_ctor_object lp_vsr_x2dveil_Smoke_instReprInstantiation_repr___closed__10_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 5}, .m_objs = {((lean_object*)&lp_vsr_x2dveil_Smoke_instReprStateOfLeader___redArg___lam__0___closed__8_value),((lean_object*)&lp_vsr_x2dveil_Smoke_instReprInstantiation_repr___closed__8_value)}};
static const lean_object* lp_vsr_x2dveil_Smoke_instReprInstantiation_repr___closed__10 = (const lean_object*)&lp_vsr_x2dveil_Smoke_instReprInstantiation_repr___closed__10_value;
static const lean_ctor_object lp_vsr_x2dveil_Smoke_instReprInstantiation_repr___closed__11_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 5}, .m_objs = {((lean_object*)&lp_vsr_x2dveil_Smoke_instReprInstantiation_repr___closed__10_value),((lean_object*)&lp_vsr_x2dveil_Smoke_instReprStateOfLeader___redArg___lam__0___closed__9_value)}};
static const lean_object* lp_vsr_x2dveil_Smoke_instReprInstantiation_repr___closed__11 = (const lean_object*)&lp_vsr_x2dveil_Smoke_instReprInstantiation_repr___closed__11_value;
static lean_once_cell_t lp_vsr_x2dveil_Smoke_instReprInstantiation_repr___closed__12_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_vsr_x2dveil_Smoke_instReprInstantiation_repr___closed__12;
static lean_once_cell_t lp_vsr_x2dveil_Smoke_instReprInstantiation_repr___closed__13_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_vsr_x2dveil_Smoke_instReprInstantiation_repr___closed__13;
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instReprInstantiation_repr(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instReprInstantiation_repr___boxed(lean_object*, lean_object*);
static const lean_closure_object lp_vsr_x2dveil_Smoke_instReprInstantiation___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_closure_object) + sizeof(void*)*0, .m_other = 0, .m_tag = 245}, .m_fun = (void*)lp_vsr_x2dveil_Smoke_instReprInstantiation_repr___boxed, .m_arity = 2, .m_num_fixed = 0, .m_objs = {} };
static const lean_object* lp_vsr_x2dveil_Smoke_instReprInstantiation___closed__0 = (const lean_object*)&lp_vsr_x2dveil_Smoke_instReprInstantiation___closed__0_value;
LEAN_EXPORT const lean_object* lp_vsr_x2dveil_Smoke_instReprInstantiation = (const lean_object*)&lp_vsr_x2dveil_Smoke_instReprInstantiation___closed__0_value;
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instInhabitedInstantiation;
static const lean_ctor_object lp_vsr_x2dveil_Smoke_ignoreStateFields___redArg___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 8, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(0) << 1) | 1)),((lean_object*)&lp_vsr_x2dveil_Smoke_instToJsonStateOfLeader___redArg___lam__0___closed__0_value),LEAN_SCALAR_PTR_LITERAL(159, 27, 153, 166, 243, 117, 185, 43)}};
static const lean_object* lp_vsr_x2dveil_Smoke_ignoreStateFields___redArg___closed__0 = (const lean_object*)&lp_vsr_x2dveil_Smoke_ignoreStateFields___redArg___closed__0_value;
static const lean_array_object lp_vsr_x2dveil_Smoke_ignoreStateFields___redArg___closed__1_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_array_object) + sizeof(void*)*1, .m_other = 0, .m_tag = 246}, .m_size = 1, .m_capacity = 1, .m_data = {((lean_object*)&lp_vsr_x2dveil_Smoke_ignoreStateFields___redArg___closed__0_value)}};
static const lean_object* lp_vsr_x2dveil_Smoke_ignoreStateFields___redArg___closed__1 = (const lean_object*)&lp_vsr_x2dveil_Smoke_ignoreStateFields___redArg___closed__1_value;
LEAN_EXPORT uint8_t lp_vsr_x2dveil_Smoke_ignoreStateFields___redArg(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_ignoreStateFields___redArg___boxed(lean_object*, lean_object*);
LEAN_EXPORT uint8_t lp_vsr_x2dveil_Smoke_ignoreStateFields(lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_ignoreStateFields___boxed(lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instLocalTheoryPropTrue(lean_object*, lean_object*, lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instLocalTheoryPropTrue___boxed(lean_object*, lean_object*, lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instLocalTheoryPropAnd(lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instLocalTheoryPropAnd___boxed(lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instLocalRPropAnd(lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instLocalRPropAnd___boxed(lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_initializer_do___redArg___lam__0(lean_object*);
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_initializer_do___redArg___lam__1(lean_object*);
LEAN_EXPORT uint8_t lp_vsr_x2dveil_Smoke_initializer_do___redArg___lam__2(lean_object*);
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_initializer_do___redArg___lam__2___boxed(lean_object*);
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_initializer_do___redArg___lam__3(lean_object*, lean_object*, lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_initializer_do___redArg___lam__3___boxed(lean_object*, lean_object*, lean_object*, lean_object*, lean_object*);
static const lean_ctor_object lp_vsr_x2dveil_Smoke_initializer_do___redArg___lam__4___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 0}, .m_objs = {((lean_object*)(((size_t)(0) << 1) | 1)),((lean_object*)(((size_t)(0) << 1) | 1))}};
static const lean_object* lp_vsr_x2dveil_Smoke_initializer_do___redArg___lam__4___closed__0 = (const lean_object*)&lp_vsr_x2dveil_Smoke_initializer_do___redArg___lam__4___closed__0_value;
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_initializer_do___redArg___lam__4(lean_object*, lean_object*, lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_initializer_do___redArg___lam__5(lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_initializer_do___redArg___lam__5___boxed(lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_initializer_do___redArg___lam__6(lean_object*, lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_initializer_do___redArg___lam__7(lean_object*);
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_initializer_do___redArg___lam__8(lean_object*, lean_object*, lean_object*);
static const lean_closure_object lp_vsr_x2dveil_Smoke_initializer_do___redArg___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_closure_object) + sizeof(void*)*0, .m_other = 0, .m_tag = 245}, .m_fun = (void*)lp_vsr_x2dveil_Smoke_initializer_do___redArg___lam__0, .m_arity = 1, .m_num_fixed = 0, .m_objs = {} };
static const lean_object* lp_vsr_x2dveil_Smoke_initializer_do___redArg___closed__0 = (const lean_object*)&lp_vsr_x2dveil_Smoke_initializer_do___redArg___closed__0_value;
static const lean_closure_object lp_vsr_x2dveil_Smoke_initializer_do___redArg___closed__1_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_closure_object) + sizeof(void*)*0, .m_other = 0, .m_tag = 245}, .m_fun = (void*)lp_vsr_x2dveil_Smoke_initializer_do___redArg___lam__1, .m_arity = 1, .m_num_fixed = 0, .m_objs = {} };
static const lean_object* lp_vsr_x2dveil_Smoke_initializer_do___redArg___closed__1 = (const lean_object*)&lp_vsr_x2dveil_Smoke_initializer_do___redArg___closed__1_value;
static const lean_closure_object lp_vsr_x2dveil_Smoke_initializer_do___redArg___closed__2_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_closure_object) + sizeof(void*)*0, .m_other = 0, .m_tag = 245}, .m_fun = (void*)lp_vsr_x2dveil_Smoke_initializer_do___redArg___lam__2___boxed, .m_arity = 1, .m_num_fixed = 0, .m_objs = {} };
static const lean_object* lp_vsr_x2dveil_Smoke_initializer_do___redArg___closed__2 = (const lean_object*)&lp_vsr_x2dveil_Smoke_initializer_do___redArg___closed__2_value;
static const lean_closure_object lp_vsr_x2dveil_Smoke_initializer_do___redArg___closed__3_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_closure_object) + sizeof(void*)*0, .m_other = 0, .m_tag = 245}, .m_fun = (void*)lp_vsr_x2dveil_Smoke_initializer_do___redArg___lam__7, .m_arity = 1, .m_num_fixed = 0, .m_objs = {} };
static const lean_object* lp_vsr_x2dveil_Smoke_initializer_do___redArg___closed__3 = (const lean_object*)&lp_vsr_x2dveil_Smoke_initializer_do___redArg___closed__3_value;
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_initializer_do___redArg(lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_initializer_do(uint8_t, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_initializer_do___boxed(lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_initializer___redArg(lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_initializer(lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_initializer___boxed(lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_initializer_ext___redArg(lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_initializer_ext(lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_initializer_ext___boxed(lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*);
LEAN_EXPORT uint8_t lp_vsr_x2dveil_Smoke_elect_do___redArg___lam__0(lean_object*);
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_elect_do___redArg___lam__0___boxed(lean_object*);
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_elect_do___redArg___lam__4(lean_object*, lean_object*, lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_elect_do___redArg___lam__4___boxed(lean_object*, lean_object*, lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_elect_do___redArg___lam__1(lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_elect_do___redArg___lam__2(lean_object*, lean_object*, lean_object*);
static lean_once_cell_t lp_vsr_x2dveil_Smoke_elect_do___redArg___lam__3___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_vsr_x2dveil_Smoke_elect_do___redArg___lam__3___closed__0;
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_elect_do___redArg___lam__3(lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, uint8_t, lean_object*);
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_elect_do___redArg___lam__3___boxed(lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_elect_do___redArg___lam__5(lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, uint8_t, lean_object*);
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_elect_do___redArg___lam__5___boxed(lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*);
static const lean_closure_object lp_vsr_x2dveil_Smoke_elect_do___redArg___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_closure_object) + sizeof(void*)*0, .m_other = 0, .m_tag = 245}, .m_fun = (void*)lp_vsr_x2dveil_Smoke_elect_do___redArg___lam__0___boxed, .m_arity = 1, .m_num_fixed = 0, .m_objs = {} };
static const lean_object* lp_vsr_x2dveil_Smoke_elect_do___redArg___closed__0 = (const lean_object*)&lp_vsr_x2dveil_Smoke_elect_do___redArg___closed__0_value;
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_elect_do___redArg(uint8_t, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_elect_do___redArg___boxed(lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_elect_do(uint8_t, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_elect_do___boxed(lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_elect___redArg___lam__7(lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_elect___redArg___lam__0(lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_elect___redArg(lean_object*, lean_object*, lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_elect(lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_elect___boxed(lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_elect_ext___redArg___lam__9(lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, uint8_t, lean_object*);
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_elect_ext___redArg___lam__9___boxed(lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_elect_ext___redArg___lam__0(lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, uint8_t, lean_object*);
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_elect_ext___redArg___lam__0___boxed(lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_elect_ext___redArg(lean_object*, lean_object*, lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_elect_ext(lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_elect_ext___boxed(lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*);
static const lean_string_object lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__127___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 5, .m_capacity = 5, .m_length = 4, .m_data = "Lean"};
static const lean_object* lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__127___closed__0 = (const lean_object*)&lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__127___closed__0_value;
static const lean_string_object lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__127___closed__1_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 7, .m_capacity = 7, .m_length = 6, .m_data = "Parser"};
static const lean_object* lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__127___closed__1 = (const lean_object*)&lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__127___closed__1_value;
static const lean_string_object lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__127___closed__2_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 7, .m_capacity = 7, .m_length = 6, .m_data = "Tactic"};
static const lean_object* lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__127___closed__2 = (const lean_object*)&lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__127___closed__2_value;
static const lean_string_object lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__127___closed__3_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 10, .m_capacity = 10, .m_length = 9, .m_data = "tacticSeq"};
static const lean_object* lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__127___closed__3 = (const lean_object*)&lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__127___closed__3_value;
static const lean_ctor_object lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__127___closed__4_value_aux_0 = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 8, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(0) << 1) | 1)),((lean_object*)&lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__127___closed__0_value),LEAN_SCALAR_PTR_LITERAL(70, 193, 83, 126, 233, 67, 208, 165)}};
static const lean_ctor_object lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__127___closed__4_value_aux_1 = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 8, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)&lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__127___closed__4_value_aux_0),((lean_object*)&lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__127___closed__1_value),LEAN_SCALAR_PTR_LITERAL(103, 136, 125, 166, 167, 98, 71, 111)}};
static const lean_ctor_object lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__127___closed__4_value_aux_2 = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 8, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)&lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__127___closed__4_value_aux_1),((lean_object*)&lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__127___closed__2_value),LEAN_SCALAR_PTR_LITERAL(166, 58, 35, 182, 187, 130, 147, 254)}};
static const lean_ctor_object lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__127___closed__4_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 8, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)&lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__127___closed__4_value_aux_2),((lean_object*)&lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__127___closed__3_value),LEAN_SCALAR_PTR_LITERAL(212, 140, 85, 215, 241, 69, 7, 118)}};
static const lean_object* lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__127___closed__4 = (const lean_object*)&lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__127___closed__4_value;
static const lean_array_object lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__127___closed__5_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_array_object) + sizeof(void*)*0, .m_other = 0, .m_tag = 246}, .m_size = 0, .m_capacity = 0, .m_data = {}};
static const lean_object* lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__127___closed__5 = (const lean_object*)&lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__127___closed__5_value;
static const lean_string_object lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__127___closed__6_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 19, .m_capacity = 19, .m_length = 18, .m_data = "tacticSeq1Indented"};
static const lean_object* lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__127___closed__6 = (const lean_object*)&lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__127___closed__6_value;
static const lean_ctor_object lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__127___closed__7_value_aux_0 = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 8, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(0) << 1) | 1)),((lean_object*)&lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__127___closed__0_value),LEAN_SCALAR_PTR_LITERAL(70, 193, 83, 126, 233, 67, 208, 165)}};
static const lean_ctor_object lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__127___closed__7_value_aux_1 = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 8, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)&lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__127___closed__7_value_aux_0),((lean_object*)&lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__127___closed__1_value),LEAN_SCALAR_PTR_LITERAL(103, 136, 125, 166, 167, 98, 71, 111)}};
static const lean_ctor_object lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__127___closed__7_value_aux_2 = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 8, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)&lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__127___closed__7_value_aux_1),((lean_object*)&lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__127___closed__2_value),LEAN_SCALAR_PTR_LITERAL(166, 58, 35, 182, 187, 130, 147, 254)}};
static const lean_ctor_object lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__127___closed__7_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 8, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)&lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__127___closed__7_value_aux_2),((lean_object*)&lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__127___closed__6_value),LEAN_SCALAR_PTR_LITERAL(223, 90, 160, 238, 133, 180, 23, 239)}};
static const lean_object* lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__127___closed__7 = (const lean_object*)&lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__127___closed__7_value;
static const lean_string_object lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__127___closed__8_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 5, .m_capacity = 5, .m_length = 4, .m_data = "null"};
static const lean_object* lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__127___closed__8 = (const lean_object*)&lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__127___closed__8_value;
static const lean_ctor_object lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__127___closed__9_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 8, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(0) << 1) | 1)),((lean_object*)&lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__127___closed__8_value),LEAN_SCALAR_PTR_LITERAL(24, 58, 49, 223, 146, 207, 197, 136)}};
static const lean_object* lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__127___closed__9 = (const lean_object*)&lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__127___closed__9_value;
static const lean_string_object lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__127___closed__10_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 5, .m_capacity = 5, .m_length = 4, .m_data = "Veil"};
static const lean_object* lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__127___closed__10 = (const lean_object*)&lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__127___closed__10_value;
static const lean_string_object lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__127___closed__11_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 18, .m_capacity = 18, .m_length = 17, .m_data = "veil_exact_theory"};
static const lean_object* lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__127___closed__11 = (const lean_object*)&lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__127___closed__11_value;
static const lean_ctor_object lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__127___closed__12_value_aux_0 = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 8, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(0) << 1) | 1)),((lean_object*)&lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__127___closed__10_value),LEAN_SCALAR_PTR_LITERAL(217, 205, 186, 196, 31, 152, 33, 229)}};
static const lean_ctor_object lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__127___closed__12_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 8, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)&lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__127___closed__12_value_aux_0),((lean_object*)&lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__127___closed__11_value),LEAN_SCALAR_PTR_LITERAL(70, 144, 102, 251, 174, 94, 0, 44)}};
static const lean_object* lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__127___closed__12 = (const lean_object*)&lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__127___closed__12_value;
static lean_once_cell_t lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__127___closed__13_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__127___closed__13;
static lean_once_cell_t lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__127___closed__14_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__127___closed__14;
static lean_once_cell_t lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__127___closed__15_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__127___closed__15;
static lean_once_cell_t lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__127___closed__16_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__127___closed__16;
static lean_once_cell_t lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__127___closed__17_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__127___closed__17;
static lean_once_cell_t lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__127___closed__18_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__127___closed__18;
static lean_once_cell_t lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__127___closed__19_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__127___closed__19;
static lean_once_cell_t lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__127___closed__20_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__127___closed__20;
static lean_once_cell_t lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__127___closed__21_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__127___closed__21;
LEAN_EXPORT lean_object* lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__127;
static const lean_string_object lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__129___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 17, .m_capacity = 17, .m_length = 16, .m_data = "veil_exact_state"};
static const lean_object* lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__129___closed__0 = (const lean_object*)&lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__129___closed__0_value;
static const lean_ctor_object lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__129___closed__1_value_aux_0 = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 8, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(0) << 1) | 1)),((lean_object*)&lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__127___closed__10_value),LEAN_SCALAR_PTR_LITERAL(217, 205, 186, 196, 31, 152, 33, 229)}};
static const lean_ctor_object lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__129___closed__1_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 8, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)&lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__129___closed__1_value_aux_0),((lean_object*)&lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__129___closed__0_value),LEAN_SCALAR_PTR_LITERAL(188, 22, 102, 165, 75, 170, 2, 162)}};
static const lean_object* lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__129___closed__1 = (const lean_object*)&lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__129___closed__1_value;
static lean_once_cell_t lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__129___closed__2_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__129___closed__2;
static lean_once_cell_t lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__129___closed__3_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__129___closed__3;
static lean_once_cell_t lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__129___closed__4_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__129___closed__4;
static lean_once_cell_t lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__129___closed__5_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__129___closed__5;
static lean_once_cell_t lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__129___closed__6_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__129___closed__6;
static lean_once_cell_t lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__129___closed__7_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__129___closed__7;
static lean_once_cell_t lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__129___closed__8_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__129___closed__8;
static lean_once_cell_t lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__129___closed__9_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__129___closed__9;
static lean_once_cell_t lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__129___closed__10_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__129___closed__10;
LEAN_EXPORT lean_object* lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__129;
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instLocalRPropOne(lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instLocalRPropOne___boxed(lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*);
LEAN_EXPORT uint8_t lp_vsr_x2dveil_Smoke_instDecidableEqLabel_decEq___redArg(lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instDecidableEqLabel_decEq___redArg___boxed(lean_object*, lean_object*, lean_object*);
LEAN_EXPORT uint8_t lp_vsr_x2dveil_Smoke_instDecidableEqLabel_decEq(lean_object*, lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instDecidableEqLabel_decEq___boxed(lean_object*, lean_object*, lean_object*, lean_object*);
LEAN_EXPORT uint8_t lp_vsr_x2dveil_Smoke_instDecidableEqLabel___redArg(lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instDecidableEqLabel___redArg___boxed(lean_object*, lean_object*, lean_object*);
LEAN_EXPORT uint8_t lp_vsr_x2dveil_Smoke_instDecidableEqLabel(lean_object*, lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instDecidableEqLabel___boxed(lean_object*, lean_object*, lean_object*, lean_object*);
static const lean_string_object lp_vsr_x2dveil_Smoke_instReprLabel_repr___redArg___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 18, .m_capacity = 18, .m_length = 17, .m_data = "Smoke.Label.elect"};
static const lean_object* lp_vsr_x2dveil_Smoke_instReprLabel_repr___redArg___closed__0 = (const lean_object*)&lp_vsr_x2dveil_Smoke_instReprLabel_repr___redArg___closed__0_value;
static const lean_ctor_object lp_vsr_x2dveil_Smoke_instReprLabel_repr___redArg___closed__1_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*1 + 0, .m_other = 1, .m_tag = 3}, .m_objs = {((lean_object*)&lp_vsr_x2dveil_Smoke_instReprLabel_repr___redArg___closed__0_value)}};
static const lean_object* lp_vsr_x2dveil_Smoke_instReprLabel_repr___redArg___closed__1 = (const lean_object*)&lp_vsr_x2dveil_Smoke_instReprLabel_repr___redArg___closed__1_value;
static const lean_ctor_object lp_vsr_x2dveil_Smoke_instReprLabel_repr___redArg___closed__2_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 5}, .m_objs = {((lean_object*)&lp_vsr_x2dveil_Smoke_instReprLabel_repr___redArg___closed__1_value),((lean_object*)(((size_t)(1) << 1) | 1))}};
static const lean_object* lp_vsr_x2dveil_Smoke_instReprLabel_repr___redArg___closed__2 = (const lean_object*)&lp_vsr_x2dveil_Smoke_instReprLabel_repr___redArg___closed__2_value;
static lean_once_cell_t lp_vsr_x2dveil_Smoke_instReprLabel_repr___redArg___closed__3_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_vsr_x2dveil_Smoke_instReprLabel_repr___redArg___closed__3;
static lean_once_cell_t lp_vsr_x2dveil_Smoke_instReprLabel_repr___redArg___closed__4_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_vsr_x2dveil_Smoke_instReprLabel_repr___redArg___closed__4;
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instReprLabel_repr___redArg(lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instReprLabel_repr___redArg___boxed(lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instReprLabel_repr(lean_object*, lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instReprLabel_repr___boxed(lean_object*, lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instReprLabel___redArg(lean_object*);
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instReprLabel(lean_object*, lean_object*);
static const lean_string_object lp_vsr_x2dveil_Smoke_instToJsonLabel_toJson___redArg___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 6, .m_capacity = 6, .m_length = 5, .m_data = "elect"};
static const lean_object* lp_vsr_x2dveil_Smoke_instToJsonLabel_toJson___redArg___closed__0 = (const lean_object*)&lp_vsr_x2dveil_Smoke_instToJsonLabel_toJson___redArg___closed__0_value;
static const lean_string_object lp_vsr_x2dveil_Smoke_instToJsonLabel_toJson___redArg___closed__1_value = {.m_header = {.m_rc = 0, .m_cs_sz = 0, .m_other = 0, .m_tag = 249}, .m_size = 2, .m_capacity = 2, .m_length = 1, .m_data = "n"};
static const lean_object* lp_vsr_x2dveil_Smoke_instToJsonLabel_toJson___redArg___closed__1 = (const lean_object*)&lp_vsr_x2dveil_Smoke_instToJsonLabel_toJson___redArg___closed__1_value;
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instToJsonLabel_toJson___redArg(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instToJsonLabel_toJson(lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instToJsonLabel___redArg(lean_object*);
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instToJsonLabel(lean_object*, lean_object*);
LEAN_EXPORT uint64_t lp_vsr_x2dveil_Smoke_instHashableLabel_hash___redArg(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instHashableLabel_hash___redArg___boxed(lean_object*, lean_object*);
LEAN_EXPORT uint64_t lp_vsr_x2dveil_Smoke_instHashableLabel_hash(lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instHashableLabel_hash___boxed(lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instHashableLabel___redArg(lean_object*);
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instHashableLabel(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_Label_proxyTypeEquiv___lam__0(lean_object*);
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_Label_proxyTypeEquiv___lam__0___boxed(lean_object*);
static const lean_closure_object lp_vsr_x2dveil_Smoke_Label_proxyTypeEquiv___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_closure_object) + sizeof(void*)*0, .m_other = 0, .m_tag = 245}, .m_fun = (void*)lp_vsr_x2dveil_Smoke_Label_proxyTypeEquiv___lam__0___boxed, .m_arity = 1, .m_num_fixed = 0, .m_objs = {} };
static const lean_object* lp_vsr_x2dveil_Smoke_Label_proxyTypeEquiv___closed__0 = (const lean_object*)&lp_vsr_x2dveil_Smoke_Label_proxyTypeEquiv___closed__0_value;
static const lean_ctor_object lp_vsr_x2dveil_Smoke_Label_proxyTypeEquiv___closed__1_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 0}, .m_objs = {((lean_object*)&lp_vsr_x2dveil_Smoke_Label_proxyTypeEquiv___closed__0_value),((lean_object*)&lp_vsr_x2dveil_Smoke_Label_proxyTypeEquiv___closed__0_value)}};
static const lean_object* lp_vsr_x2dveil_Smoke_Label_proxyTypeEquiv___closed__1 = (const lean_object*)&lp_vsr_x2dveil_Smoke_Label_proxyTypeEquiv___closed__1_value;
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_Label_proxyTypeEquiv(lean_object*);
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instEnumerationLabel___redArg___lam__0(lean_object*, lean_object*);
static lean_once_cell_t lp_vsr_x2dveil_Smoke_instEnumerationLabel___redArg___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_vsr_x2dveil_Smoke_instEnumerationLabel___redArg___closed__0;
static lean_once_cell_t lp_vsr_x2dveil_Smoke_instEnumerationLabel___redArg___closed__1_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_vsr_x2dveil_Smoke_instEnumerationLabel___redArg___closed__1;
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instEnumerationLabel___redArg(lean_object*);
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instEnumerationLabel(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instFinEncodableInjOnlyLabel___redArg___lam__0(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instFinEncodableInjOnlyLabel___redArg(lean_object*);
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instFinEncodableInjOnlyLabel(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instInhabitedLabel_default___redArg(lean_object*);
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instInhabitedLabel_default___redArg___boxed(lean_object*);
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instInhabitedLabel_default(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instInhabitedLabel_default___boxed(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instInhabitedLabel___redArg(lean_object*);
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instInhabitedLabel___redArg___boxed(lean_object*);
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instInhabitedLabel(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instInhabitedLabel___boxed(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_ActionTag__IndT_toCtorIdx(lean_object*);
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_ActionTag__IndT_ofNat(lean_object*);
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_ActionTag__IndT_ofNat___boxed(lean_object*);
LEAN_EXPORT uint8_t lp_vsr_x2dveil_Smoke_instDecidableEqActionTag__IndT(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instDecidableEqActionTag__IndT___boxed(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instInhabitedActionTag__IndT_default;
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instInhabitedActionTag__IndT;
static const lean_ctor_object lp_vsr_x2dveil_Smoke_instReprActionTag__IndT___lam__0___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*1 + 0, .m_other = 1, .m_tag = 3}, .m_objs = {((lean_object*)&lp_vsr_x2dveil_Smoke_instToJsonLabel_toJson___redArg___closed__0_value)}};
static const lean_object* lp_vsr_x2dveil_Smoke_instReprActionTag__IndT___lam__0___closed__0 = (const lean_object*)&lp_vsr_x2dveil_Smoke_instReprActionTag__IndT___lam__0___closed__0_value;
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instReprActionTag__IndT___lam__0(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instReprActionTag__IndT___lam__0___boxed(lean_object*, lean_object*);
static const lean_closure_object lp_vsr_x2dveil_Smoke_instReprActionTag__IndT___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_closure_object) + sizeof(void*)*0, .m_other = 0, .m_tag = 245}, .m_fun = (void*)lp_vsr_x2dveil_Smoke_instReprActionTag__IndT___lam__0___boxed, .m_arity = 2, .m_num_fixed = 0, .m_objs = {} };
static const lean_object* lp_vsr_x2dveil_Smoke_instReprActionTag__IndT___closed__0 = (const lean_object*)&lp_vsr_x2dveil_Smoke_instReprActionTag__IndT___closed__0_value;
LEAN_EXPORT const lean_object* lp_vsr_x2dveil_Smoke_instReprActionTag__IndT = (const lean_object*)&lp_vsr_x2dveil_Smoke_instReprActionTag__IndT___closed__0_value;
static lean_once_cell_t lp_vsr_x2dveil_Smoke_instToJsonActionTag__IndT___lam__0___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_vsr_x2dveil_Smoke_instToJsonActionTag__IndT___lam__0___closed__0;
static lean_once_cell_t lp_vsr_x2dveil_Smoke_instToJsonActionTag__IndT___lam__0___closed__1_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_vsr_x2dveil_Smoke_instToJsonActionTag__IndT___lam__0___closed__1;
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instToJsonActionTag__IndT___lam__0(lean_object*);
static const lean_closure_object lp_vsr_x2dveil_Smoke_instToJsonActionTag__IndT___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_closure_object) + sizeof(void*)*0, .m_other = 0, .m_tag = 245}, .m_fun = (void*)lp_vsr_x2dveil_Smoke_instToJsonActionTag__IndT___lam__0, .m_arity = 1, .m_num_fixed = 0, .m_objs = {} };
static const lean_object* lp_vsr_x2dveil_Smoke_instToJsonActionTag__IndT___closed__0 = (const lean_object*)&lp_vsr_x2dveil_Smoke_instToJsonActionTag__IndT___closed__0_value;
LEAN_EXPORT const lean_object* lp_vsr_x2dveil_Smoke_instToJsonActionTag__IndT = (const lean_object*)&lp_vsr_x2dveil_Smoke_instToJsonActionTag__IndT___closed__0_value;
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instActionTag__EnumClassActionTag__IndT;
LEAN_EXPORT uint64_t lp_vsr_x2dveil_Smoke_instHashableActionTag__IndT_hash(lean_object*);
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instHashableActionTag__IndT_hash___boxed(lean_object*);
static const lean_closure_object lp_vsr_x2dveil_Smoke_instHashableActionTag__IndT___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_closure_object) + sizeof(void*)*0, .m_other = 0, .m_tag = 245}, .m_fun = (void*)lp_vsr_x2dveil_Smoke_instHashableActionTag__IndT_hash___boxed, .m_arity = 1, .m_num_fixed = 0, .m_objs = {} };
static const lean_object* lp_vsr_x2dveil_Smoke_instHashableActionTag__IndT___closed__0 = (const lean_object*)&lp_vsr_x2dveil_Smoke_instHashableActionTag__IndT___closed__0_value;
LEAN_EXPORT const lean_object* lp_vsr_x2dveil_Smoke_instHashableActionTag__IndT = (const lean_object*)&lp_vsr_x2dveil_Smoke_instHashableActionTag__IndT___closed__0_value;
static const lean_ctor_object lp_vsr_x2dveil_Smoke_ActionTag__IndT_enumList___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 1}, .m_objs = {((lean_object*)(((size_t)(0) << 1) | 1)),((lean_object*)(((size_t)(0) << 1) | 1))}};
static const lean_object* lp_vsr_x2dveil_Smoke_ActionTag__IndT_enumList___closed__0 = (const lean_object*)&lp_vsr_x2dveil_Smoke_ActionTag__IndT_enumList___closed__0_value;
LEAN_EXPORT const lean_object* lp_vsr_x2dveil_Smoke_ActionTag__IndT_enumList = (const lean_object*)&lp_vsr_x2dveil_Smoke_ActionTag__IndT_enumList___closed__0_value;
LEAN_EXPORT const lean_object* lp_vsr_x2dveil_Smoke_instFintypeActionTag__IndT = (const lean_object*)&lp_vsr_x2dveil_Smoke_ActionTag__IndT_enumList___closed__0_value;
LEAN_EXPORT const lean_object* lp_vsr_x2dveil_Smoke_instEnumerationActionTag__IndT = (const lean_object*)&lp_vsr_x2dveil_Smoke_ActionTag__IndT_enumList___closed__0_value;
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instFinEncodableActionTag__IndT___lam__0(lean_object*);
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instFinEncodableActionTag__IndT___lam__1(lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instFinEncodableActionTag__IndT___lam__1___boxed(lean_object*, lean_object*);
static const lean_closure_object lp_vsr_x2dveil_Smoke_instFinEncodableActionTag__IndT___closed__0_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_closure_object) + sizeof(void*)*0, .m_other = 0, .m_tag = 245}, .m_fun = (void*)lp_vsr_x2dveil_Smoke_instFinEncodableActionTag__IndT___lam__0, .m_arity = 1, .m_num_fixed = 0, .m_objs = {} };
static const lean_object* lp_vsr_x2dveil_Smoke_instFinEncodableActionTag__IndT___closed__0 = (const lean_object*)&lp_vsr_x2dveil_Smoke_instFinEncodableActionTag__IndT___closed__0_value;
static const lean_closure_object lp_vsr_x2dveil_Smoke_instFinEncodableActionTag__IndT___closed__1_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_closure_object) + sizeof(void*)*1, .m_other = 0, .m_tag = 245}, .m_fun = (void*)lp_vsr_x2dveil_Smoke_instFinEncodableActionTag__IndT___lam__1___boxed, .m_arity = 2, .m_num_fixed = 1, .m_objs = {((lean_object*)&lp_vsr_x2dveil_Smoke_ActionTag__IndT_enumList___closed__0_value)} };
static const lean_object* lp_vsr_x2dveil_Smoke_instFinEncodableActionTag__IndT___closed__1 = (const lean_object*)&lp_vsr_x2dveil_Smoke_instFinEncodableActionTag__IndT___closed__1_value;
static lean_once_cell_t lp_vsr_x2dveil_Smoke_instFinEncodableActionTag__IndT___closed__2_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_vsr_x2dveil_Smoke_instFinEncodableActionTag__IndT___closed__2;
static const lean_ctor_object lp_vsr_x2dveil_Smoke_instFinEncodableActionTag__IndT___closed__3_value = {.m_header = {.m_rc = 0, .m_cs_sz = sizeof(lean_ctor_object) + sizeof(void*)*2 + 0, .m_other = 2, .m_tag = 0}, .m_objs = {((lean_object*)&lp_vsr_x2dveil_Smoke_instFinEncodableActionTag__IndT___closed__0_value),((lean_object*)&lp_vsr_x2dveil_Smoke_instFinEncodableActionTag__IndT___closed__1_value)}};
static const lean_object* lp_vsr_x2dveil_Smoke_instFinEncodableActionTag__IndT___closed__3 = (const lean_object*)&lp_vsr_x2dveil_Smoke_instFinEncodableActionTag__IndT___closed__3_value;
static lean_once_cell_t lp_vsr_x2dveil_Smoke_instFinEncodableActionTag__IndT___closed__4_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_vsr_x2dveil_Smoke_instFinEncodableActionTag__IndT___closed__4;
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instFinEncodableActionTag__IndT;
static lean_once_cell_t lp_vsr_x2dveil_Smoke_instOrdActionTag__IndT___closed__0_once = LEAN_ONCE_CELL_INITIALIZER;
static lean_object* lp_vsr_x2dveil_Smoke_instOrdActionTag__IndT___closed__0;
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instOrdActionTag__IndT;
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_NextAct___redArg(lean_object*, lean_object*, lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_NextAct(lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_NextAct___boxed(lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*, lean_object*);
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_State_Label_toCtorIdx(lean_object* v_x_1_){
_start:
{
lean_object* v___x_2_; 
v___x_2_ = lean_unsigned_to_nat(0u);
return v___x_2_;
}
}
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_State_Label_toDomain(lean_object* v_node_5_, lean_object* v_____veil__f_6_){
_start:
{
lean_object* v___x_7_; 
v___x_7_ = ((lean_object*)(lp_vsr_x2dveil_Smoke_State_Label_toDomain___closed__0));
return v___x_7_;
}
}
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instEnumerationForIteratedProd___redArg(lean_object* v_inst_8_){
_start:
{
lean_object* v___x_9_; lean_object* v___x_10_; lean_object* v___x_11_; 
v___x_9_ = lean_alloc_ctor(1, 1, 0);
lean_ctor_set(v___x_9_, 0, v_inst_8_);
v___x_10_ = lean_box(0);
v___x_11_ = lean_alloc_ctor(0, 2, 0);
lean_ctor_set(v___x_11_, 0, v___x_9_);
lean_ctor_set(v___x_11_, 1, v___x_10_);
return v___x_11_;
}
}
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instEnumerationForIteratedProd(lean_object* v_node_12_, lean_object* v_inst_13_, lean_object* v_____veil__f_14_){
_start:
{
lean_object* v___x_15_; 
v___x_15_ = lp_vsr_x2dveil_Smoke_instEnumerationForIteratedProd___redArg(v_inst_13_);
return v___x_15_;
}
}
LEAN_EXPORT uint8_t lp_vsr_x2dveil_Smoke_instEnumerationForIteratedProdAllSomeCheck(lean_object* v_l_16_){
_start:
{
uint8_t v___x_17_; 
v___x_17_ = 1;
return v___x_17_;
}
}
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instEnumerationForIteratedProdAllSomeCheck___boxed(lean_object* v_l_18_){
_start:
{
uint8_t v_res_19_; lean_object* v_r_20_; 
v_res_19_ = lp_vsr_x2dveil_Smoke_instEnumerationForIteratedProdAllSomeCheck(v_l_18_);
v_r_20_ = lean_box(v_res_19_);
return v_r_20_;
}
}
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instInhabitedStateFieldConcreteType___redArg(lean_object* v_inst0_21_){
_start:
{
lean_inc(v_inst0_21_);
return v_inst0_21_;
}
}
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instInhabitedStateFieldConcreteType___redArg___boxed(lean_object* v_inst0_22_){
_start:
{
lean_object* v_res_23_; 
v_res_23_ = lp_vsr_x2dveil_Smoke_instInhabitedStateFieldConcreteType___redArg(v_inst0_22_);
lean_dec(v_inst0_22_);
return v_res_23_;
}
}
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instInhabitedStateFieldConcreteType(lean_object* v_00_u03c7_24_, lean_object* v_inst0_25_){
_start:
{
lean_inc(v_inst0_25_);
return v_inst0_25_;
}
}
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instInhabitedStateFieldConcreteType___boxed(lean_object* v_00_u03c7_26_, lean_object* v_inst0_27_){
_start:
{
lean_object* v_res_28_; 
v_res_28_ = lp_vsr_x2dveil_Smoke_instInhabitedStateFieldConcreteType(v_00_u03c7_26_, v_inst0_27_);
lean_dec(v_inst0_27_);
return v_res_28_;
}
}
LEAN_EXPORT uint64_t lp_vsr_x2dveil_Smoke_instHashableStateOfLeader___redArg___lam__0(lean_object* v_inst0_29_, lean_object* v_x_30_){
_start:
{
lean_object* v___x_31_; uint64_t v___x_32_; 
v___x_31_ = lean_apply_1(v_inst0_29_, v_x_30_);
v___x_32_ = lean_unbox_uint64(v___x_31_);
lean_dec_ref(v___x_31_);
return v___x_32_;
}
}
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instHashableStateOfLeader___redArg___lam__0___boxed(lean_object* v_inst0_33_, lean_object* v_x_34_){
_start:
{
uint64_t v_res_35_; lean_object* v_r_36_; 
v_res_35_ = lp_vsr_x2dveil_Smoke_instHashableStateOfLeader___redArg___lam__0(v_inst0_33_, v_x_34_);
v_r_36_ = lean_box_uint64(v_res_35_);
return v_r_36_;
}
}
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instHashableStateOfLeader___redArg(lean_object* v_inst0_37_){
_start:
{
lean_object* v___f_38_; 
v___f_38_ = lean_alloc_closure((void*)(lp_vsr_x2dveil_Smoke_instHashableStateOfLeader___redArg___lam__0___boxed), 2, 1);
lean_closure_set(v___f_38_, 0, v_inst0_37_);
return v___f_38_;
}
}
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instHashableStateOfLeader(lean_object* v_00_u03c7_39_, lean_object* v_inst0_40_){
_start:
{
lean_object* v___f_41_; 
v___f_41_ = lean_alloc_closure((void*)(lp_vsr_x2dveil_Smoke_instHashableStateOfLeader___redArg___lam__0___boxed), 2, 1);
lean_closure_set(v___f_41_, 0, v_inst0_40_);
return v___f_41_;
}
}
LEAN_EXPORT uint8_t lp_vsr_x2dveil_Smoke_instBEqStateOfLeader___redArg___lam__0(lean_object* v_inst0_42_, lean_object* v_x_43_, lean_object* v_x_44_){
_start:
{
lean_object* v___x_45_; uint8_t v___x_46_; 
v___x_45_ = lean_apply_2(v_inst0_42_, v_x_43_, v_x_44_);
v___x_46_ = lean_unbox(v___x_45_);
return v___x_46_;
}
}
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instBEqStateOfLeader___redArg___lam__0___boxed(lean_object* v_inst0_47_, lean_object* v_x_48_, lean_object* v_x_49_){
_start:
{
uint8_t v_res_50_; lean_object* v_r_51_; 
v_res_50_ = lp_vsr_x2dveil_Smoke_instBEqStateOfLeader___redArg___lam__0(v_inst0_47_, v_x_48_, v_x_49_);
v_r_51_ = lean_box(v_res_50_);
return v_r_51_;
}
}
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instBEqStateOfLeader___redArg(lean_object* v_inst0_52_){
_start:
{
lean_object* v___f_53_; 
v___f_53_ = lean_alloc_closure((void*)(lp_vsr_x2dveil_Smoke_instBEqStateOfLeader___redArg___lam__0___boxed), 3, 1);
lean_closure_set(v___f_53_, 0, v_inst0_52_);
return v___f_53_;
}
}
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instBEqStateOfLeader(lean_object* v_00_u03c7_54_, lean_object* v_inst0_55_){
_start:
{
lean_object* v___f_56_; 
v___f_56_ = lean_alloc_closure((void*)(lp_vsr_x2dveil_Smoke_instBEqStateOfLeader___redArg___lam__0___boxed), 3, 1);
lean_closure_set(v___f_56_, 0, v_inst0_55_);
return v___f_56_;
}
}
LEAN_EXPORT uint8_t lp_vsr_x2dveil_Smoke_instDecidableEqStateOfLeader___redArg(lean_object* v_inst0_57_, lean_object* v_x_58_, lean_object* v_x_59_){
_start:
{
lean_object* v___x_60_; uint8_t v___x_61_; 
v___x_60_ = lean_apply_2(v_inst0_57_, v_x_58_, v_x_59_);
v___x_61_ = lean_unbox(v___x_60_);
return v___x_61_;
}
}
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instDecidableEqStateOfLeader___redArg___boxed(lean_object* v_inst0_62_, lean_object* v_x_63_, lean_object* v_x_64_){
_start:
{
uint8_t v_res_65_; lean_object* v_r_66_; 
v_res_65_ = lp_vsr_x2dveil_Smoke_instDecidableEqStateOfLeader___redArg(v_inst0_62_, v_x_63_, v_x_64_);
v_r_66_ = lean_box(v_res_65_);
return v_r_66_;
}
}
LEAN_EXPORT uint8_t lp_vsr_x2dveil_Smoke_instDecidableEqStateOfLeader(lean_object* v_00_u03c7_67_, lean_object* v_inst0_68_, lean_object* v_x_69_, lean_object* v_x_70_){
_start:
{
lean_object* v___x_71_; uint8_t v___x_72_; 
v___x_71_ = lean_apply_2(v_inst0_68_, v_x_69_, v_x_70_);
v___x_72_ = lean_unbox(v___x_71_);
return v___x_72_;
}
}
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instDecidableEqStateOfLeader___boxed(lean_object* v_00_u03c7_73_, lean_object* v_inst0_74_, lean_object* v_x_75_, lean_object* v_x_76_){
_start:
{
uint8_t v_res_77_; lean_object* v_r_78_; 
v_res_77_ = lp_vsr_x2dveil_Smoke_instDecidableEqStateOfLeader(v_00_u03c7_73_, v_inst0_74_, v_x_75_, v_x_76_);
v_r_78_ = lean_box(v_res_77_);
return v_r_78_;
}
}
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instToJsonStateOfLeader___redArg___lam__0(lean_object* v_inst0_80_, lean_object* v_x_81_){
_start:
{
lean_object* v___x_82_; lean_object* v___x_83_; lean_object* v___x_84_; lean_object* v___x_85_; lean_object* v___x_86_; lean_object* v___x_87_; 
v___x_82_ = ((lean_object*)(lp_vsr_x2dveil_Smoke_instToJsonStateOfLeader___redArg___lam__0___closed__0));
v___x_83_ = lean_apply_1(v_inst0_80_, v_x_81_);
v___x_84_ = lean_alloc_ctor(0, 2, 0);
lean_ctor_set(v___x_84_, 0, v___x_82_);
lean_ctor_set(v___x_84_, 1, v___x_83_);
v___x_85_ = lean_box(0);
v___x_86_ = lean_alloc_ctor(1, 2, 0);
lean_ctor_set(v___x_86_, 0, v___x_84_);
lean_ctor_set(v___x_86_, 1, v___x_85_);
v___x_87_ = l_Lean_Json_mkObj(v___x_86_);
lean_dec_ref_known(v___x_86_, 2);
return v___x_87_;
}
}
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instToJsonStateOfLeader___redArg(lean_object* v_inst0_88_){
_start:
{
lean_object* v___f_89_; 
v___f_89_ = lean_alloc_closure((void*)(lp_vsr_x2dveil_Smoke_instToJsonStateOfLeader___redArg___lam__0), 2, 1);
lean_closure_set(v___f_89_, 0, v_inst0_88_);
return v___f_89_;
}
}
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instToJsonStateOfLeader(lean_object* v_00_u03c7_90_, lean_object* v_inst0_91_){
_start:
{
lean_object* v___f_92_; 
v___f_92_ = lean_alloc_closure((void*)(lp_vsr_x2dveil_Smoke_instToJsonStateOfLeader___redArg___lam__0), 2, 1);
lean_closure_set(v___f_92_, 0, v_inst0_91_);
return v___f_92_;
}
}
static lean_object* _init_lp_vsr_x2dveil_Smoke_instReprStateOfLeader___redArg___lam__0___closed__6(void){
_start:
{
lean_object* v___x_101_; lean_object* v___x_102_; 
v___x_101_ = ((lean_object*)(lp_vsr_x2dveil_Smoke_instReprStateOfLeader___redArg___lam__0___closed__0));
v___x_102_ = lean_string_length(v___x_101_);
return v___x_102_;
}
}
static lean_object* _init_lp_vsr_x2dveil_Smoke_instReprStateOfLeader___redArg___lam__0___closed__7(void){
_start:
{
lean_object* v___x_103_; lean_object* v___x_104_; 
v___x_103_ = lean_obj_once(&lp_vsr_x2dveil_Smoke_instReprStateOfLeader___redArg___lam__0___closed__6, &lp_vsr_x2dveil_Smoke_instReprStateOfLeader___redArg___lam__0___closed__6_once, _init_lp_vsr_x2dveil_Smoke_instReprStateOfLeader___redArg___lam__0___closed__6);
v___x_104_ = lean_nat_to_int(v___x_103_);
return v___x_104_;
}
}
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instReprStateOfLeader___redArg___lam__0(lean_object* v_inst0_109_, lean_object* v___f_110_, lean_object* v_s_111_, lean_object* v_n_112_){
_start:
{
lean_object* v___x_113_; lean_object* v___x_114_; lean_object* v___x_115_; lean_object* v___x_116_; lean_object* v___x_117_; lean_object* v___x_118_; lean_object* v___x_119_; lean_object* v___x_120_; lean_object* v___x_121_; lean_object* v___x_122_; lean_object* v___x_123_; lean_object* v___x_124_; lean_object* v___x_125_; uint8_t v___x_126_; lean_object* v___x_127_; 
v___x_113_ = ((lean_object*)(lp_vsr_x2dveil_Smoke_instReprStateOfLeader___redArg___lam__0___closed__2));
v___x_114_ = lean_apply_2(v_inst0_109_, v_s_111_, v_n_112_);
v___x_115_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_115_, 0, v___x_113_);
lean_ctor_set(v___x_115_, 1, v___x_114_);
v___x_116_ = lean_box(0);
v___x_117_ = lean_alloc_ctor(1, 2, 0);
lean_ctor_set(v___x_117_, 0, v___x_115_);
lean_ctor_set(v___x_117_, 1, v___x_116_);
v___x_118_ = ((lean_object*)(lp_vsr_x2dveil_Smoke_instReprStateOfLeader___redArg___lam__0___closed__4));
v___x_119_ = l_Std_Format_joinSep___redArg(v___f_110_, v___x_117_, v___x_118_);
v___x_120_ = lean_obj_once(&lp_vsr_x2dveil_Smoke_instReprStateOfLeader___redArg___lam__0___closed__7, &lp_vsr_x2dveil_Smoke_instReprStateOfLeader___redArg___lam__0___closed__7_once, _init_lp_vsr_x2dveil_Smoke_instReprStateOfLeader___redArg___lam__0___closed__7);
v___x_121_ = ((lean_object*)(lp_vsr_x2dveil_Smoke_instReprStateOfLeader___redArg___lam__0___closed__8));
v___x_122_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_122_, 0, v___x_121_);
lean_ctor_set(v___x_122_, 1, v___x_119_);
v___x_123_ = ((lean_object*)(lp_vsr_x2dveil_Smoke_instReprStateOfLeader___redArg___lam__0___closed__9));
v___x_124_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_124_, 0, v___x_122_);
lean_ctor_set(v___x_124_, 1, v___x_123_);
v___x_125_ = lean_alloc_ctor(4, 2, 0);
lean_ctor_set(v___x_125_, 0, v___x_120_);
lean_ctor_set(v___x_125_, 1, v___x_124_);
v___x_126_ = 0;
v___x_127_ = lean_alloc_ctor(6, 1, 1);
lean_ctor_set(v___x_127_, 0, v___x_125_);
lean_ctor_set_uint8(v___x_127_, sizeof(void*)*1, v___x_126_);
return v___x_127_;
}
}
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instReprStateOfLeader___redArg(lean_object* v_inst0_129_){
_start:
{
lean_object* v___f_130_; lean_object* v___f_131_; 
v___f_130_ = ((lean_object*)(lp_vsr_x2dveil_Smoke_instReprStateOfLeader___redArg___closed__0));
v___f_131_ = lean_alloc_closure((void*)(lp_vsr_x2dveil_Smoke_instReprStateOfLeader___redArg___lam__0), 4, 2);
lean_closure_set(v___f_131_, 0, v_inst0_129_);
lean_closure_set(v___f_131_, 1, v___f_130_);
return v___f_131_;
}
}
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instReprStateOfLeader(lean_object* v_00_u03c7_132_, lean_object* v_inst0_133_){
_start:
{
lean_object* v___x_134_; 
v___x_134_ = lp_vsr_x2dveil_Smoke_instReprStateOfLeader___redArg(v_inst0_133_);
return v___x_134_;
}
}
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_State__ho(lean_object* v_00_u03c7_135_){
_start:
{
lean_object* v___x_136_; 
v___x_136_ = lean_box(0);
return v___x_136_;
}
}
static lean_object* _init_lp_vsr_x2dveil_Smoke_instFieldRepresentation___redArg___closed__0(void){
_start:
{
lean_object* v___x_137_; lean_object* v___x_138_; 
v___x_137_ = ((lean_object*)(lp_vsr_x2dveil_Smoke_State_Label_toDomain___closed__0));
v___x_138_ = lp_veil_Veil_IteratedProd_x27_equiv(v___x_137_);
return v___x_138_;
}
}
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instFieldRepresentation___redArg(lean_object* v_inst_139_, lean_object* v_inst_140_){
_start:
{
lean_object* v___x_141_; lean_object* v___x_142_; lean_object* v___x_143_; lean_object* v___x_144_; lean_object* v___x_145_; lean_object* v___x_146_; 
v___x_141_ = ((lean_object*)(lp_vsr_x2dveil_Smoke_State_Label_toDomain___closed__0));
v___x_142_ = lp_veil_Veil_instFinmapLikeBoolExtTreeSetOfTransCmp___redArg(v_inst_140_);
v___x_143_ = lean_obj_once(&lp_vsr_x2dveil_Smoke_instFieldRepresentation___redArg___closed__0, &lp_vsr_x2dveil_Smoke_instFieldRepresentation___redArg___closed__0_once, _init_lp_vsr_x2dveil_Smoke_instFieldRepresentation___redArg___closed__0);
v___x_144_ = lean_box(0);
v___x_145_ = lean_alloc_ctor(0, 2, 0);
lean_ctor_set(v___x_145_, 0, v_inst_139_);
lean_ctor_set(v___x_145_, 1, v___x_144_);
v___x_146_ = lp_veil_Veil_instFinmapLikeAsFieldRep___redArg(v___x_141_, v___x_142_, v___x_143_, v___x_145_);
return v___x_146_;
}
}
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instFieldRepresentation(lean_object* v_node_147_, lean_object* v_inst_148_, lean_object* v_inst_149_, lean_object* v_inst_150_, lean_object* v_inst_151_, lean_object* v_____veil__f_152_){
_start:
{
lean_object* v___x_153_; 
v___x_153_ = lp_vsr_x2dveil_Smoke_instFieldRepresentation___redArg(v_inst_149_, v_inst_150_);
return v___x_153_;
}
}
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instFieldRepresentation___boxed(lean_object* v_node_154_, lean_object* v_inst_155_, lean_object* v_inst_156_, lean_object* v_inst_157_, lean_object* v_inst_158_, lean_object* v_____veil__f_159_){
_start:
{
lean_object* v_res_160_; 
v_res_160_ = lp_vsr_x2dveil_Smoke_instFieldRepresentation(v_node_154_, v_inst_155_, v_inst_156_, v_inst_157_, v_inst_158_, v_____veil__f_159_);
lean_dec_ref(v_inst_155_);
return v_res_160_;
}
}
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instAbstractFieldRepresentation___redArg(lean_object* v_inst_161_){
_start:
{
lean_object* v___x_162_; lean_object* v___x_163_; lean_object* v___x_164_; lean_object* v___x_165_; 
v___x_162_ = ((lean_object*)(lp_vsr_x2dveil_Smoke_State_Label_toDomain___closed__0));
v___x_163_ = lean_box(0);
v___x_164_ = lean_alloc_ctor(0, 2, 0);
lean_ctor_set(v___x_164_, 0, v_inst_161_);
lean_ctor_set(v___x_164_, 1, v___x_163_);
v___x_165_ = lp_veil_Veil_canonicalFieldRepresentation___redArg(v___x_162_, v___x_164_);
return v___x_165_;
}
}
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instAbstractFieldRepresentation(lean_object* v_node_166_, lean_object* v_inst_167_, lean_object* v_____veil__f_168_){
_start:
{
lean_object* v___x_169_; 
v___x_169_ = lp_vsr_x2dveil_Smoke_instAbstractFieldRepresentation___redArg(v_inst_167_);
return v___x_169_;
}
}
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instEnumerationStateOfLeader___redArg___lam__0(lean_object* v_leader_170_, lean_object* v_res_171_){
_start:
{
lean_object* v___x_172_; 
v___x_172_ = lean_alloc_ctor(1, 2, 0);
lean_ctor_set(v___x_172_, 0, v_leader_170_);
lean_ctor_set(v___x_172_, 1, v_res_171_);
return v___x_172_;
}
}
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instEnumerationStateOfLeader___redArg___lam__1(lean_object* v_inst0_173_, lean_object* v_x_174_){
_start:
{
lean_inc(v_inst0_173_);
return v_inst0_173_;
}
}
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instEnumerationStateOfLeader___redArg___lam__1___boxed(lean_object* v_inst0_175_, lean_object* v_x_176_){
_start:
{
lean_object* v_res_177_; 
v_res_177_ = lp_vsr_x2dveil_Smoke_instEnumerationStateOfLeader___redArg___lam__1(v_inst0_175_, v_x_176_);
lean_dec(v_inst0_175_);
return v_res_177_;
}
}
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instEnumerationStateOfLeader___redArg(lean_object* v_inst0_179_){
_start:
{
lean_object* v___f_180_; lean_object* v___f_181_; lean_object* v___x_182_; lean_object* v___x_183_; lean_object* v___x_184_; lean_object* v___x_185_; lean_object* v___x_186_; 
v___f_180_ = ((lean_object*)(lp_vsr_x2dveil_Smoke_instEnumerationStateOfLeader___redArg___closed__0));
v___f_181_ = lean_alloc_closure((void*)(lp_vsr_x2dveil_Smoke_instEnumerationStateOfLeader___redArg___lam__1___boxed), 2, 1);
lean_closure_set(v___f_181_, 0, v_inst0_179_);
v___x_182_ = lean_box(0);
v___x_183_ = ((lean_object*)(lp_vsr_x2dveil_Smoke_State_Label_toDomain___closed__0));
v___x_184_ = lean_box(0);
v___x_185_ = lean_alloc_ctor(0, 2, 0);
lean_ctor_set(v___x_185_, 0, v___f_181_);
lean_ctor_set(v___x_185_, 1, v___x_184_);
v___x_186_ = lp_veil_Veil_IteratedProd_foldMap___redArg(v___x_183_, v___x_182_, v___f_180_, v___x_185_);
return v___x_186_;
}
}
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instEnumerationStateOfLeader(lean_object* v_00_u03c7_187_, lean_object* v_inst0_188_){
_start:
{
lean_object* v___x_189_; 
v___x_189_ = lp_vsr_x2dveil_Smoke_instEnumerationStateOfLeader___redArg(v_inst0_188_);
return v___x_189_;
}
}
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instInhabitedTheory_default(lean_object* v_node_190_){
_start:
{
lean_object* v___x_191_; 
v___x_191_ = lean_box(0);
return v___x_191_;
}
}
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instInhabitedTheory(lean_object* v_a_192_){
_start:
{
lean_object* v___x_193_; 
v___x_193_ = lean_box(0);
return v___x_193_;
}
}
static lean_object* _init_lp_vsr_x2dveil_Smoke_instReprTheory___lam__0___closed__4(void){
_start:
{
lean_object* v___x_203_; lean_object* v___x_204_; lean_object* v___x_205_; 
v___x_203_ = ((lean_object*)(lp_vsr_x2dveil_Smoke_instReprTheory___lam__0___closed__3));
v___x_204_ = lean_obj_once(&lp_vsr_x2dveil_Smoke_instReprStateOfLeader___redArg___lam__0___closed__7, &lp_vsr_x2dveil_Smoke_instReprStateOfLeader___redArg___lam__0___closed__7_once, _init_lp_vsr_x2dveil_Smoke_instReprStateOfLeader___redArg___lam__0___closed__7);
v___x_205_ = lean_alloc_ctor(4, 2, 0);
lean_ctor_set(v___x_205_, 0, v___x_204_);
lean_ctor_set(v___x_205_, 1, v___x_203_);
return v___x_205_;
}
}
static lean_object* _init_lp_vsr_x2dveil_Smoke_instReprTheory___lam__0___closed__5(void){
_start:
{
uint8_t v___x_206_; lean_object* v___x_207_; lean_object* v___x_208_; 
v___x_206_ = 0;
v___x_207_ = lean_obj_once(&lp_vsr_x2dveil_Smoke_instReprTheory___lam__0___closed__4, &lp_vsr_x2dveil_Smoke_instReprTheory___lam__0___closed__4_once, _init_lp_vsr_x2dveil_Smoke_instReprTheory___lam__0___closed__4);
v___x_208_ = lean_alloc_ctor(6, 1, 1);
lean_ctor_set(v___x_208_, 0, v___x_207_);
lean_ctor_set_uint8(v___x_208_, sizeof(void*)*1, v___x_206_);
return v___x_208_;
}
}
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instReprTheory___lam__0(lean_object* v_s_209_, lean_object* v_n_210_){
_start:
{
lean_object* v___x_211_; 
v___x_211_ = lean_obj_once(&lp_vsr_x2dveil_Smoke_instReprTheory___lam__0___closed__5, &lp_vsr_x2dveil_Smoke_instReprTheory___lam__0___closed__5_once, _init_lp_vsr_x2dveil_Smoke_instReprTheory___lam__0___closed__5);
return v___x_211_;
}
}
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instReprTheory___lam__0___boxed(lean_object* v_s_212_, lean_object* v_n_213_){
_start:
{
lean_object* v_res_214_; 
v_res_214_ = lp_vsr_x2dveil_Smoke_instReprTheory___lam__0(v_s_212_, v_n_213_);
lean_dec(v_n_213_);
return v_res_214_;
}
}
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instReprTheory(lean_object* v_node_216_){
_start:
{
lean_object* v___f_217_; 
v___f_217_ = ((lean_object*)(lp_vsr_x2dveil_Smoke_instReprTheory___closed__0));
return v___f_217_;
}
}
static lean_object* _init_lp_vsr_x2dveil_Smoke_instToJsonTheory___lam__0___closed__0(void){
_start:
{
lean_object* v___x_218_; lean_object* v___x_219_; 
v___x_218_ = lean_box(0);
v___x_219_ = l_Lean_Json_mkObj(v___x_218_);
return v___x_219_;
}
}
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instToJsonTheory___lam__0(lean_object* v_x_220_){
_start:
{
lean_object* v___x_221_; 
v___x_221_ = lean_obj_once(&lp_vsr_x2dveil_Smoke_instToJsonTheory___lam__0___closed__0, &lp_vsr_x2dveil_Smoke_instToJsonTheory___lam__0___closed__0_once, _init_lp_vsr_x2dveil_Smoke_instToJsonTheory___lam__0___closed__0);
return v___x_221_;
}
}
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instToJsonTheory(lean_object* v_node_223_){
_start:
{
lean_object* v___f_224_; 
v___f_224_ = ((lean_object*)(lp_vsr_x2dveil_Smoke_instToJsonTheory___closed__0));
return v___f_224_;
}
}
static lean_object* _init_lp_vsr_x2dveil_Smoke_instReprInstantiation_repr___closed__9(void){
_start:
{
lean_object* v___x_243_; lean_object* v___x_244_; 
v___x_243_ = lean_obj_once(&lp_vsr_x2dveil_Smoke_instReprStateOfLeader___redArg___lam__0___closed__6, &lp_vsr_x2dveil_Smoke_instReprStateOfLeader___redArg___lam__0___closed__6_once, _init_lp_vsr_x2dveil_Smoke_instReprStateOfLeader___redArg___lam__0___closed__6);
v___x_244_ = lean_nat_to_int(v___x_243_);
return v___x_244_;
}
}
static lean_object* _init_lp_vsr_x2dveil_Smoke_instReprInstantiation_repr___closed__12(void){
_start:
{
lean_object* v___x_251_; lean_object* v___x_252_; lean_object* v___x_253_; 
v___x_251_ = ((lean_object*)(lp_vsr_x2dveil_Smoke_instReprInstantiation_repr___closed__11));
v___x_252_ = lean_obj_once(&lp_vsr_x2dveil_Smoke_instReprInstantiation_repr___closed__9, &lp_vsr_x2dveil_Smoke_instReprInstantiation_repr___closed__9_once, _init_lp_vsr_x2dveil_Smoke_instReprInstantiation_repr___closed__9);
v___x_253_ = lean_alloc_ctor(4, 2, 0);
lean_ctor_set(v___x_253_, 0, v___x_252_);
lean_ctor_set(v___x_253_, 1, v___x_251_);
return v___x_253_;
}
}
static lean_object* _init_lp_vsr_x2dveil_Smoke_instReprInstantiation_repr___closed__13(void){
_start:
{
uint8_t v___x_254_; lean_object* v___x_255_; lean_object* v___x_256_; 
v___x_254_ = 0;
v___x_255_ = lean_obj_once(&lp_vsr_x2dveil_Smoke_instReprInstantiation_repr___closed__12, &lp_vsr_x2dveil_Smoke_instReprInstantiation_repr___closed__12_once, _init_lp_vsr_x2dveil_Smoke_instReprInstantiation_repr___closed__12);
v___x_256_ = lean_alloc_ctor(6, 1, 1);
lean_ctor_set(v___x_256_, 0, v___x_255_);
lean_ctor_set_uint8(v___x_256_, sizeof(void*)*1, v___x_254_);
return v___x_256_;
}
}
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instReprInstantiation_repr(lean_object* v_x_257_, lean_object* v_prec_258_){
_start:
{
lean_object* v___x_259_; 
v___x_259_ = lean_obj_once(&lp_vsr_x2dveil_Smoke_instReprInstantiation_repr___closed__13, &lp_vsr_x2dveil_Smoke_instReprInstantiation_repr___closed__13_once, _init_lp_vsr_x2dveil_Smoke_instReprInstantiation_repr___closed__13);
return v___x_259_;
}
}
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instReprInstantiation_repr___boxed(lean_object* v_x_260_, lean_object* v_prec_261_){
_start:
{
lean_object* v_res_262_; 
v_res_262_ = lp_vsr_x2dveil_Smoke_instReprInstantiation_repr(v_x_260_, v_prec_261_);
lean_dec(v_prec_261_);
return v_res_262_;
}
}
static lean_object* _init_lp_vsr_x2dveil_Smoke_instInhabitedInstantiation(void){
_start:
{
lean_object* v___x_265_; 
v___x_265_ = lean_box(0);
return v___x_265_;
}
}
LEAN_EXPORT uint8_t lp_vsr_x2dveil_Smoke_ignoreStateFields___redArg(lean_object* v_id_272_, lean_object* v_stack_273_){
_start:
{
lean_object* v___x_274_; lean_object* v___x_275_; uint8_t v___x_276_; 
v___x_274_ = ((lean_object*)(lp_vsr_x2dveil_Smoke_ignoreStateFields___redArg___closed__1));
v___x_275_ = l_Lean_Syntax_getId(v_id_272_);
v___x_276_ = lp_auto_Array_contains___at___00Auto_Deriving_ToExpr_mkInstanceCmds_spec__0(v___x_274_, v___x_275_);
if (v___x_276_ == 0)
{
uint8_t v___x_277_; 
v___x_277_ = lp_veil_Veil_isCapital(v___x_275_);
if (v___x_277_ == 0)
{
lean_dec(v_stack_273_);
return v___x_277_;
}
else
{
uint8_t v___x_278_; 
v___x_278_ = lp_veil_List_any___at___00Veil_isVeilProcedureContext_spec__0(v_stack_273_);
return v___x_278_;
}
}
else
{
lean_dec(v___x_275_);
lean_dec(v_stack_273_);
return v___x_276_;
}
}
}
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_ignoreStateFields___redArg___boxed(lean_object* v_id_279_, lean_object* v_stack_280_){
_start:
{
uint8_t v_res_281_; lean_object* v_r_282_; 
v_res_281_ = lp_vsr_x2dveil_Smoke_ignoreStateFields___redArg(v_id_279_, v_stack_280_);
lean_dec(v_id_279_);
v_r_282_ = lean_box(v_res_281_);
return v_r_282_;
}
}
LEAN_EXPORT uint8_t lp_vsr_x2dveil_Smoke_ignoreStateFields(lean_object* v_id_283_, lean_object* v_stack_284_, lean_object* v_x_285_){
_start:
{
uint8_t v___x_286_; 
v___x_286_ = lp_vsr_x2dveil_Smoke_ignoreStateFields___redArg(v_id_283_, v_stack_284_);
return v___x_286_;
}
}
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_ignoreStateFields___boxed(lean_object* v_id_287_, lean_object* v_stack_288_, lean_object* v_x_289_){
_start:
{
uint8_t v_res_290_; lean_object* v_r_291_; 
v_res_290_ = lp_vsr_x2dveil_Smoke_ignoreStateFields(v_id_287_, v_stack_288_, v_x_289_);
lean_dec_ref(v_x_289_);
lean_dec(v_id_287_);
v_r_291_ = lean_box(v_res_290_);
return v_r_291_;
}
}
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instLocalTheoryPropTrue(lean_object* v_00_u03c1_292_, lean_object* v_node_293_, lean_object* v_node__dec__eq_294_, lean_object* v_node__inhabited_295_, lean_object* v_00_u03c1__sub_296_){
_start:
{
lean_object* v___x_297_; 
v___x_297_ = lean_box(0);
return v___x_297_;
}
}
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instLocalTheoryPropTrue___boxed(lean_object* v_00_u03c1_298_, lean_object* v_node_299_, lean_object* v_node__dec__eq_300_, lean_object* v_node__inhabited_301_, lean_object* v_00_u03c1__sub_302_){
_start:
{
lean_object* v_res_303_; 
v_res_303_ = lp_vsr_x2dveil_Smoke_instLocalTheoryPropTrue(v_00_u03c1_298_, v_node_299_, v_node__dec__eq_300_, v_node__inhabited_301_, v_00_u03c1__sub_302_);
lean_dec_ref(v_00_u03c1__sub_302_);
lean_dec(v_node__inhabited_301_);
lean_dec_ref(v_node__dec__eq_300_);
return v_res_303_;
}
}
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instLocalTheoryPropAnd(lean_object* v_00_u03c1_304_, lean_object* v_node_305_, lean_object* v_node__dec__eq_306_, lean_object* v_node__inhabited_307_, lean_object* v_00_u03c1__sub_308_, lean_object* v_p_309_, lean_object* v_q_310_, lean_object* v_inst1_311_, lean_object* v_inst2_312_){
_start:
{
lean_object* v___x_313_; 
v___x_313_ = lean_box(0);
return v___x_313_;
}
}
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instLocalTheoryPropAnd___boxed(lean_object* v_00_u03c1_314_, lean_object* v_node_315_, lean_object* v_node__dec__eq_316_, lean_object* v_node__inhabited_317_, lean_object* v_00_u03c1__sub_318_, lean_object* v_p_319_, lean_object* v_q_320_, lean_object* v_inst1_321_, lean_object* v_inst2_322_){
_start:
{
lean_object* v_res_323_; 
v_res_323_ = lp_vsr_x2dveil_Smoke_instLocalTheoryPropAnd(v_00_u03c1_314_, v_node_315_, v_node__dec__eq_316_, v_node__inhabited_317_, v_00_u03c1__sub_318_, v_p_319_, v_q_320_, v_inst1_321_, v_inst2_322_);
lean_dec_ref(v_00_u03c1__sub_318_);
lean_dec(v_node__inhabited_317_);
lean_dec_ref(v_node__dec__eq_316_);
return v_res_323_;
}
}
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instLocalRPropAnd(lean_object* v_00_u03c1_324_, lean_object* v_00_u03c3_325_, lean_object* v_node_326_, lean_object* v_node__dec__eq_327_, lean_object* v_node__inhabited_328_, lean_object* v_00_u03c7_329_, lean_object* v_00_u03c7__rep_330_, lean_object* v_00_u03c7__rep__lawful_331_, lean_object* v_00_u03c3__sub_332_, lean_object* v_00_u03c1__sub_333_, lean_object* v_p_334_, lean_object* v_q_335_, lean_object* v_inst1_336_, lean_object* v_inst2_337_){
_start:
{
lean_object* v___x_338_; 
v___x_338_ = lean_box(0);
return v___x_338_;
}
}
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instLocalRPropAnd___boxed(lean_object* v_00_u03c1_339_, lean_object* v_00_u03c3_340_, lean_object* v_node_341_, lean_object* v_node__dec__eq_342_, lean_object* v_node__inhabited_343_, lean_object* v_00_u03c7_344_, lean_object* v_00_u03c7__rep_345_, lean_object* v_00_u03c7__rep__lawful_346_, lean_object* v_00_u03c3__sub_347_, lean_object* v_00_u03c1__sub_348_, lean_object* v_p_349_, lean_object* v_q_350_, lean_object* v_inst1_351_, lean_object* v_inst2_352_){
_start:
{
lean_object* v_res_353_; 
v_res_353_ = lp_vsr_x2dveil_Smoke_instLocalRPropAnd(v_00_u03c1_339_, v_00_u03c3_340_, v_node_341_, v_node__dec__eq_342_, v_node__inhabited_343_, v_00_u03c7_344_, v_00_u03c7__rep_345_, v_00_u03c7__rep__lawful_346_, v_00_u03c3__sub_347_, v_00_u03c1__sub_348_, v_p_349_, v_q_350_, v_inst1_351_, v_inst2_352_);
lean_dec_ref(v_00_u03c1__sub_348_);
lean_dec_ref(v_00_u03c3__sub_347_);
lean_dec_ref(v_00_u03c7__rep_345_);
lean_dec(v_node__inhabited_343_);
lean_dec_ref(v_node__dec__eq_342_);
return v_res_353_;
}
}
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_initializer_do___redArg___lam__0(lean_object* v___y_354_){
_start:
{
lean_object* v___x_355_; 
v___x_355_ = lean_alloc_ctor(0, 1, 0);
lean_ctor_set(v___x_355_, 0, v___y_354_);
return v___x_355_;
}
}
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_initializer_do___redArg___lam__1(lean_object* v___y_356_){
_start:
{
lean_object* v___x_357_; 
v___x_357_ = lean_alloc_ctor(0, 1, 0);
lean_ctor_set(v___x_357_, 0, v___y_356_);
return v___x_357_;
}
}
LEAN_EXPORT uint8_t lp_vsr_x2dveil_Smoke_initializer_do___redArg___lam__2(lean_object* v_N_358_){
_start:
{
uint8_t v___x_359_; 
v___x_359_ = 0;
return v___x_359_;
}
}
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_initializer_do___redArg___lam__2___boxed(lean_object* v_N_360_){
_start:
{
uint8_t v_res_361_; lean_object* v_r_362_; 
v_res_361_ = lp_vsr_x2dveil_Smoke_initializer_do___redArg___lam__2(v_N_360_);
lean_dec(v_N_360_);
v_r_362_ = lean_box(v_res_361_);
return v_r_362_;
}
}
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_initializer_do___redArg___lam__3(lean_object* v_00_u03c3__sub_363_, lean_object* v___x_364_, lean_object* v___x_365_, lean_object* v___y_366_, lean_object* v___y_367_){
_start:
{
lean_object* v_setIn_368_; lean_object* v___x_370_; uint8_t v_isShared_371_; uint8_t v_isSharedCheck_378_; 
v_setIn_368_ = lean_ctor_get(v_00_u03c3__sub_363_, 0);
v_isSharedCheck_378_ = !lean_is_exclusive(v_00_u03c3__sub_363_);
if (v_isSharedCheck_378_ == 0)
{
lean_object* v_unused_379_; 
v_unused_379_ = lean_ctor_get(v_00_u03c3__sub_363_, 1);
lean_dec(v_unused_379_);
v___x_370_ = v_00_u03c3__sub_363_;
v_isShared_371_ = v_isSharedCheck_378_;
goto v_resetjp_369_;
}
else
{
lean_inc(v_setIn_368_);
lean_dec(v_00_u03c3__sub_363_);
v___x_370_ = lean_box(0);
v_isShared_371_ = v_isSharedCheck_378_;
goto v_resetjp_369_;
}
v_resetjp_369_:
{
lean_object* v___x_372_; lean_object* v___x_373_; lean_object* v___x_375_; 
v___x_372_ = lean_apply_2(v_setIn_368_, v___x_364_, v___y_367_);
v___x_373_ = lean_alloc_ctor(1, 1, 0);
lean_ctor_set(v___x_373_, 0, v___x_365_);
if (v_isShared_371_ == 0)
{
lean_ctor_set(v___x_370_, 1, v___x_372_);
lean_ctor_set(v___x_370_, 0, v___x_373_);
v___x_375_ = v___x_370_;
goto v_reusejp_374_;
}
else
{
lean_object* v_reuseFailAlloc_377_; 
v_reuseFailAlloc_377_ = lean_alloc_ctor(0, 2, 0);
lean_ctor_set(v_reuseFailAlloc_377_, 0, v___x_373_);
lean_ctor_set(v_reuseFailAlloc_377_, 1, v___x_372_);
v___x_375_ = v_reuseFailAlloc_377_;
goto v_reusejp_374_;
}
v_reusejp_374_:
{
lean_object* v___x_376_; 
v___x_376_ = lean_alloc_ctor(0, 1, 0);
lean_ctor_set(v___x_376_, 0, v___x_375_);
return v___x_376_;
}
}
}
}
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_initializer_do___redArg___lam__3___boxed(lean_object* v_00_u03c3__sub_380_, lean_object* v___x_381_, lean_object* v___x_382_, lean_object* v___y_383_, lean_object* v___y_384_){
_start:
{
lean_object* v_res_385_; 
v_res_385_ = lp_vsr_x2dveil_Smoke_initializer_do___redArg___lam__3(v_00_u03c3__sub_380_, v___x_381_, v___x_382_, v___y_383_, v___y_384_);
lean_dec(v___y_383_);
return v_res_385_;
}
}
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_initializer_do___redArg___lam__4(lean_object* v_00_u03c7__rep_389_, lean_object* v___f_390_, lean_object* v_00_u03c3__sub_391_, lean_object* v___f_392_, lean_object* v_____veil__state_393_){
_start:
{
lean_object* v___x_394_; lean_object* v___x_395_; lean_object* v_set_396_; lean_object* v___x_398_; uint8_t v_isShared_399_; uint8_t v_isSharedCheck_410_; 
v___x_394_ = lean_box(0);
v___x_395_ = lean_apply_1(v_00_u03c7__rep_389_, v___x_394_);
v_set_396_ = lean_ctor_get(v___x_395_, 1);
v_isSharedCheck_410_ = !lean_is_exclusive(v___x_395_);
if (v_isSharedCheck_410_ == 0)
{
lean_object* v_unused_411_; 
v_unused_411_ = lean_ctor_get(v___x_395_, 0);
lean_dec(v_unused_411_);
v___x_398_ = v___x_395_;
v_isShared_399_ = v_isSharedCheck_410_;
goto v_resetjp_397_;
}
else
{
lean_inc(v_set_396_);
lean_dec(v___x_395_);
v___x_398_ = lean_box(0);
v_isShared_399_ = v_isSharedCheck_410_;
goto v_resetjp_397_;
}
v_resetjp_397_:
{
lean_object* v___x_400_; lean_object* v___x_401_; lean_object* v___x_403_; 
v___x_400_ = lean_box(0);
v___x_401_ = ((lean_object*)(lp_vsr_x2dveil_Smoke_initializer_do___redArg___lam__4___closed__0));
if (v_isShared_399_ == 0)
{
lean_ctor_set(v___x_398_, 1, v___f_390_);
lean_ctor_set(v___x_398_, 0, v___x_401_);
v___x_403_ = v___x_398_;
goto v_reusejp_402_;
}
else
{
lean_object* v_reuseFailAlloc_409_; 
v_reuseFailAlloc_409_ = lean_alloc_ctor(0, 2, 0);
lean_ctor_set(v_reuseFailAlloc_409_, 0, v___x_401_);
lean_ctor_set(v_reuseFailAlloc_409_, 1, v___f_390_);
v___x_403_ = v_reuseFailAlloc_409_;
goto v_reusejp_402_;
}
v_reusejp_402_:
{
lean_object* v___x_404_; lean_object* v___x_405_; lean_object* v___x_406_; lean_object* v___f_407_; lean_object* v___x_408_; 
v___x_404_ = lean_box(0);
v___x_405_ = lean_alloc_ctor(1, 2, 0);
lean_ctor_set(v___x_405_, 0, v___x_403_);
lean_ctor_set(v___x_405_, 1, v___x_404_);
v___x_406_ = lean_apply_2(v_set_396_, v___x_405_, v_____veil__state_393_);
v___f_407_ = lean_alloc_closure((void*)(lp_vsr_x2dveil_Smoke_initializer_do___redArg___lam__3___boxed), 5, 3);
lean_closure_set(v___f_407_, 0, v_00_u03c3__sub_391_);
lean_closure_set(v___f_407_, 1, v___x_406_);
lean_closure_set(v___f_407_, 2, v___x_400_);
v___x_408_ = lean_alloc_ctor(1, 2, 0);
lean_ctor_set(v___x_408_, 0, v___f_407_);
lean_ctor_set(v___x_408_, 1, v___f_392_);
return v___x_408_;
}
}
}
}
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_initializer_do___redArg___lam__5(lean_object* v_getFrom_412_, lean_object* v___y_413_, lean_object* v___y_414_){
_start:
{
lean_object* v___x_415_; lean_object* v___x_416_; lean_object* v___x_417_; lean_object* v___x_418_; 
lean_inc(v___y_414_);
v___x_415_ = lean_apply_1(v_getFrom_412_, v___y_414_);
v___x_416_ = lean_alloc_ctor(1, 1, 0);
lean_ctor_set(v___x_416_, 0, v___x_415_);
v___x_417_ = lean_alloc_ctor(0, 2, 0);
lean_ctor_set(v___x_417_, 0, v___x_416_);
lean_ctor_set(v___x_417_, 1, v___y_414_);
v___x_418_ = lean_alloc_ctor(0, 1, 0);
lean_ctor_set(v___x_418_, 0, v___x_417_);
return v___x_418_;
}
}
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_initializer_do___redArg___lam__5___boxed(lean_object* v_getFrom_419_, lean_object* v___y_420_, lean_object* v___y_421_){
_start:
{
lean_object* v_res_422_; 
v_res_422_ = lp_vsr_x2dveil_Smoke_initializer_do___redArg___lam__5(v_getFrom_419_, v___y_420_, v___y_421_);
lean_dec(v___y_420_);
return v_res_422_;
}
}
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_initializer_do___redArg___lam__6(lean_object* v_00_u03c3__sub_423_, lean_object* v___f_424_, lean_object* v___f_425_, lean_object* v_____veil__theory_426_){
_start:
{
lean_object* v_getFrom_427_; lean_object* v___x_429_; uint8_t v_isShared_430_; uint8_t v_isSharedCheck_436_; 
v_getFrom_427_ = lean_ctor_get(v_00_u03c3__sub_423_, 1);
v_isSharedCheck_436_ = !lean_is_exclusive(v_00_u03c3__sub_423_);
if (v_isSharedCheck_436_ == 0)
{
lean_object* v_unused_437_; 
v_unused_437_ = lean_ctor_get(v_00_u03c3__sub_423_, 0);
lean_dec(v_unused_437_);
v___x_429_ = v_00_u03c3__sub_423_;
v_isShared_430_ = v_isSharedCheck_436_;
goto v_resetjp_428_;
}
else
{
lean_inc(v_getFrom_427_);
lean_dec(v_00_u03c3__sub_423_);
v___x_429_ = lean_box(0);
v_isShared_430_ = v_isSharedCheck_436_;
goto v_resetjp_428_;
}
v_resetjp_428_:
{
lean_object* v___f_431_; lean_object* v___x_433_; 
v___f_431_ = lean_alloc_closure((void*)(lp_vsr_x2dveil_Smoke_initializer_do___redArg___lam__5___boxed), 3, 1);
lean_closure_set(v___f_431_, 0, v_getFrom_427_);
if (v_isShared_430_ == 0)
{
lean_ctor_set_tag(v___x_429_, 1);
lean_ctor_set(v___x_429_, 1, v___f_424_);
lean_ctor_set(v___x_429_, 0, v___f_431_);
v___x_433_ = v___x_429_;
goto v_reusejp_432_;
}
else
{
lean_object* v_reuseFailAlloc_435_; 
v_reuseFailAlloc_435_ = lean_alloc_ctor(1, 2, 0);
lean_ctor_set(v_reuseFailAlloc_435_, 0, v___f_431_);
lean_ctor_set(v_reuseFailAlloc_435_, 1, v___f_424_);
v___x_433_ = v_reuseFailAlloc_435_;
goto v_reusejp_432_;
}
v_reusejp_432_:
{
lean_object* v___x_434_; 
v___x_434_ = lp_Loom_NonDetT_bind___redArg(v___x_433_, v___f_425_);
return v___x_434_;
}
}
}
}
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_initializer_do___redArg___lam__7(lean_object* v___y_438_){
_start:
{
lean_object* v___x_439_; 
v___x_439_ = lean_alloc_ctor(0, 1, 0);
lean_ctor_set(v___x_439_, 0, v___y_438_);
return v___x_439_;
}
}
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_initializer_do___redArg___lam__8(lean_object* v_00_u03c1__sub_440_, lean_object* v___y_441_, lean_object* v___y_442_){
_start:
{
lean_object* v___x_443_; lean_object* v___x_444_; lean_object* v___x_445_; lean_object* v___x_446_; 
v___x_443_ = lean_apply_1(v_00_u03c1__sub_440_, v___y_441_);
v___x_444_ = lean_alloc_ctor(1, 1, 0);
lean_ctor_set(v___x_444_, 0, v___x_443_);
v___x_445_ = lean_alloc_ctor(0, 2, 0);
lean_ctor_set(v___x_445_, 0, v___x_444_);
lean_ctor_set(v___x_445_, 1, v___y_442_);
v___x_446_ = lean_alloc_ctor(0, 1, 0);
lean_ctor_set(v___x_446_, 0, v___x_445_);
return v___x_446_;
}
}
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_initializer_do___redArg(lean_object* v_00_u03c7__rep_451_, lean_object* v_00_u03c3__sub_452_, lean_object* v_00_u03c1__sub_453_){
_start:
{
lean_object* v___f_454_; lean_object* v___f_455_; lean_object* v___f_456_; lean_object* v___f_457_; lean_object* v___f_458_; lean_object* v___f_459_; lean_object* v___f_460_; lean_object* v___x_461_; lean_object* v___x_462_; 
v___f_454_ = ((lean_object*)(lp_vsr_x2dveil_Smoke_initializer_do___redArg___closed__0));
v___f_455_ = ((lean_object*)(lp_vsr_x2dveil_Smoke_initializer_do___redArg___closed__1));
v___f_456_ = ((lean_object*)(lp_vsr_x2dveil_Smoke_initializer_do___redArg___closed__2));
lean_inc_ref(v_00_u03c3__sub_452_);
v___f_457_ = lean_alloc_closure((void*)(lp_vsr_x2dveil_Smoke_initializer_do___redArg___lam__4), 5, 4);
lean_closure_set(v___f_457_, 0, v_00_u03c7__rep_451_);
lean_closure_set(v___f_457_, 1, v___f_456_);
lean_closure_set(v___f_457_, 2, v_00_u03c3__sub_452_);
lean_closure_set(v___f_457_, 3, v___f_455_);
v___f_458_ = lean_alloc_closure((void*)(lp_vsr_x2dveil_Smoke_initializer_do___redArg___lam__6), 4, 3);
lean_closure_set(v___f_458_, 0, v_00_u03c3__sub_452_);
lean_closure_set(v___f_458_, 1, v___f_454_);
lean_closure_set(v___f_458_, 2, v___f_457_);
v___f_459_ = ((lean_object*)(lp_vsr_x2dveil_Smoke_initializer_do___redArg___closed__3));
v___f_460_ = lean_alloc_closure((void*)(lp_vsr_x2dveil_Smoke_initializer_do___redArg___lam__8), 3, 1);
lean_closure_set(v___f_460_, 0, v_00_u03c1__sub_453_);
v___x_461_ = lean_alloc_ctor(1, 2, 0);
lean_ctor_set(v___x_461_, 0, v___f_460_);
lean_ctor_set(v___x_461_, 1, v___f_459_);
v___x_462_ = lp_Loom_NonDetT_bind___redArg(v___x_461_, v___f_458_);
return v___x_462_;
}
}
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_initializer_do(uint8_t v_____veil__mode_463_, lean_object* v_00_u03c1_464_, lean_object* v_00_u03c3_465_, lean_object* v_node_466_, lean_object* v_node__dec__eq_467_, lean_object* v_node__inhabited_468_, lean_object* v_00_u03c7_469_, lean_object* v_00_u03c7__rep_470_, lean_object* v_00_u03c7__rep__lawful_471_, lean_object* v_00_u03c3__sub_472_, lean_object* v_00_u03c1__sub_473_){
_start:
{
lean_object* v___x_474_; 
v___x_474_ = lp_vsr_x2dveil_Smoke_initializer_do___redArg(v_00_u03c7__rep_470_, v_00_u03c3__sub_472_, v_00_u03c1__sub_473_);
return v___x_474_;
}
}
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_initializer_do___boxed(lean_object* v_____veil__mode_475_, lean_object* v_00_u03c1_476_, lean_object* v_00_u03c3_477_, lean_object* v_node_478_, lean_object* v_node__dec__eq_479_, lean_object* v_node__inhabited_480_, lean_object* v_00_u03c7_481_, lean_object* v_00_u03c7__rep_482_, lean_object* v_00_u03c7__rep__lawful_483_, lean_object* v_00_u03c3__sub_484_, lean_object* v_00_u03c1__sub_485_){
_start:
{
uint8_t v_____veil__mode_boxed_486_; lean_object* v_res_487_; 
v_____veil__mode_boxed_486_ = lean_unbox(v_____veil__mode_475_);
v_res_487_ = lp_vsr_x2dveil_Smoke_initializer_do(v_____veil__mode_boxed_486_, v_00_u03c1_476_, v_00_u03c3_477_, v_node_478_, v_node__dec__eq_479_, v_node__inhabited_480_, v_00_u03c7_481_, v_00_u03c7__rep_482_, v_00_u03c7__rep__lawful_483_, v_00_u03c3__sub_484_, v_00_u03c1__sub_485_);
lean_dec(v_node__inhabited_480_);
lean_dec_ref(v_node__dec__eq_479_);
return v_res_487_;
}
}
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_initializer___redArg(lean_object* v_00_u03c7__rep_488_, lean_object* v_00_u03c3__sub_489_, lean_object* v_00_u03c1__sub_490_){
_start:
{
lean_object* v___f_491_; lean_object* v___f_492_; lean_object* v___f_493_; lean_object* v___f_494_; lean_object* v___f_495_; lean_object* v___f_496_; lean_object* v___f_497_; lean_object* v___x_498_; lean_object* v___x_499_; 
v___f_491_ = ((lean_object*)(lp_vsr_x2dveil_Smoke_initializer_do___redArg___closed__0));
v___f_492_ = ((lean_object*)(lp_vsr_x2dveil_Smoke_initializer_do___redArg___closed__1));
v___f_493_ = ((lean_object*)(lp_vsr_x2dveil_Smoke_initializer_do___redArg___closed__2));
lean_inc_ref(v_00_u03c3__sub_489_);
v___f_494_ = lean_alloc_closure((void*)(lp_vsr_x2dveil_Smoke_initializer_do___redArg___lam__4), 5, 4);
lean_closure_set(v___f_494_, 0, v_00_u03c7__rep_488_);
lean_closure_set(v___f_494_, 1, v___f_493_);
lean_closure_set(v___f_494_, 2, v_00_u03c3__sub_489_);
lean_closure_set(v___f_494_, 3, v___f_492_);
v___f_495_ = lean_alloc_closure((void*)(lp_vsr_x2dveil_Smoke_initializer_do___redArg___lam__6), 4, 3);
lean_closure_set(v___f_495_, 0, v_00_u03c3__sub_489_);
lean_closure_set(v___f_495_, 1, v___f_491_);
lean_closure_set(v___f_495_, 2, v___f_494_);
v___f_496_ = ((lean_object*)(lp_vsr_x2dveil_Smoke_initializer_do___redArg___closed__3));
v___f_497_ = lean_alloc_closure((void*)(lp_vsr_x2dveil_Smoke_initializer_do___redArg___lam__8), 3, 1);
lean_closure_set(v___f_497_, 0, v_00_u03c1__sub_490_);
v___x_498_ = lean_alloc_ctor(1, 2, 0);
lean_ctor_set(v___x_498_, 0, v___f_497_);
lean_ctor_set(v___x_498_, 1, v___f_496_);
v___x_499_ = lp_Loom_NonDetT_bind___redArg(v___x_498_, v___f_495_);
return v___x_499_;
}
}
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_initializer(lean_object* v_00_u03c1_500_, lean_object* v_00_u03c3_501_, lean_object* v_node_502_, lean_object* v_node__dec__eq_503_, lean_object* v_node__inhabited_504_, lean_object* v_00_u03c7_505_, lean_object* v_00_u03c7__rep_506_, lean_object* v_00_u03c7__rep__lawful_507_, lean_object* v_00_u03c3__sub_508_, lean_object* v_00_u03c1__sub_509_){
_start:
{
lean_object* v___x_510_; 
v___x_510_ = lp_vsr_x2dveil_Smoke_initializer___redArg(v_00_u03c7__rep_506_, v_00_u03c3__sub_508_, v_00_u03c1__sub_509_);
return v___x_510_;
}
}
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_initializer___boxed(lean_object* v_00_u03c1_511_, lean_object* v_00_u03c3_512_, lean_object* v_node_513_, lean_object* v_node__dec__eq_514_, lean_object* v_node__inhabited_515_, lean_object* v_00_u03c7_516_, lean_object* v_00_u03c7__rep_517_, lean_object* v_00_u03c7__rep__lawful_518_, lean_object* v_00_u03c3__sub_519_, lean_object* v_00_u03c1__sub_520_){
_start:
{
lean_object* v_res_521_; 
v_res_521_ = lp_vsr_x2dveil_Smoke_initializer(v_00_u03c1_511_, v_00_u03c3_512_, v_node_513_, v_node__dec__eq_514_, v_node__inhabited_515_, v_00_u03c7_516_, v_00_u03c7__rep_517_, v_00_u03c7__rep__lawful_518_, v_00_u03c3__sub_519_, v_00_u03c1__sub_520_);
lean_dec(v_node__inhabited_515_);
lean_dec_ref(v_node__dec__eq_514_);
return v_res_521_;
}
}
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_initializer_ext___redArg(lean_object* v_00_u03c7__rep_522_, lean_object* v_00_u03c3__sub_523_, lean_object* v_00_u03c1__sub_524_){
_start:
{
lean_object* v___f_525_; lean_object* v___f_526_; lean_object* v___f_527_; lean_object* v___f_528_; lean_object* v___f_529_; lean_object* v___f_530_; lean_object* v___f_531_; lean_object* v___x_532_; lean_object* v___x_533_; lean_object* v___x_534_; 
v___f_525_ = ((lean_object*)(lp_vsr_x2dveil_Smoke_initializer_do___redArg___closed__0));
v___f_526_ = ((lean_object*)(lp_vsr_x2dveil_Smoke_initializer_do___redArg___closed__1));
v___f_527_ = ((lean_object*)(lp_vsr_x2dveil_Smoke_initializer_do___redArg___closed__2));
lean_inc_ref(v_00_u03c3__sub_523_);
v___f_528_ = lean_alloc_closure((void*)(lp_vsr_x2dveil_Smoke_initializer_do___redArg___lam__4), 5, 4);
lean_closure_set(v___f_528_, 0, v_00_u03c7__rep_522_);
lean_closure_set(v___f_528_, 1, v___f_527_);
lean_closure_set(v___f_528_, 2, v_00_u03c3__sub_523_);
lean_closure_set(v___f_528_, 3, v___f_526_);
v___f_529_ = lean_alloc_closure((void*)(lp_vsr_x2dveil_Smoke_initializer_do___redArg___lam__6), 4, 3);
lean_closure_set(v___f_529_, 0, v_00_u03c3__sub_523_);
lean_closure_set(v___f_529_, 1, v___f_525_);
lean_closure_set(v___f_529_, 2, v___f_528_);
v___f_530_ = ((lean_object*)(lp_vsr_x2dveil_Smoke_initializer_do___redArg___closed__3));
v___f_531_ = lean_alloc_closure((void*)(lp_vsr_x2dveil_Smoke_initializer_do___redArg___lam__8), 3, 1);
lean_closure_set(v___f_531_, 0, v_00_u03c1__sub_524_);
v___x_532_ = lean_alloc_ctor(1, 2, 0);
lean_ctor_set(v___x_532_, 0, v___f_531_);
lean_ctor_set(v___x_532_, 1, v___f_530_);
v___x_533_ = lp_Loom_NonDetT_bind___redArg(v___x_532_, v___f_529_);
v___x_534_ = lp_veil_Veil_VeilM_returnUnit___redArg(v___x_533_);
return v___x_534_;
}
}
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_initializer_ext(lean_object* v_00_u03c1_535_, lean_object* v_00_u03c3_536_, lean_object* v_node_537_, lean_object* v_node__dec__eq_538_, lean_object* v_node__inhabited_539_, lean_object* v_00_u03c7_540_, lean_object* v_00_u03c7__rep_541_, lean_object* v_00_u03c7__rep__lawful_542_, lean_object* v_00_u03c3__sub_543_, lean_object* v_00_u03c1__sub_544_){
_start:
{
lean_object* v___x_545_; 
v___x_545_ = lp_vsr_x2dveil_Smoke_initializer_ext___redArg(v_00_u03c7__rep_541_, v_00_u03c3__sub_543_, v_00_u03c1__sub_544_);
return v___x_545_;
}
}
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_initializer_ext___boxed(lean_object* v_00_u03c1_546_, lean_object* v_00_u03c3_547_, lean_object* v_node_548_, lean_object* v_node__dec__eq_549_, lean_object* v_node__inhabited_550_, lean_object* v_00_u03c7_551_, lean_object* v_00_u03c7__rep_552_, lean_object* v_00_u03c7__rep__lawful_553_, lean_object* v_00_u03c3__sub_554_, lean_object* v_00_u03c1__sub_555_){
_start:
{
lean_object* v_res_556_; 
v_res_556_ = lp_vsr_x2dveil_Smoke_initializer_ext(v_00_u03c1_546_, v_00_u03c3_547_, v_node_548_, v_node__dec__eq_549_, v_node__inhabited_550_, v_00_u03c7_551_, v_00_u03c7__rep_552_, v_00_u03c7__rep__lawful_553_, v_00_u03c3__sub_554_, v_00_u03c1__sub_555_);
lean_dec(v_node__inhabited_550_);
lean_dec_ref(v_node__dec__eq_549_);
return v_res_556_;
}
}
LEAN_EXPORT uint8_t lp_vsr_x2dveil_Smoke_elect_do___redArg___lam__0(lean_object* v_x_557_){
_start:
{
uint8_t v___x_558_; 
v___x_558_ = 1;
return v___x_558_;
}
}
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_elect_do___redArg___lam__0___boxed(lean_object* v_x_559_){
_start:
{
uint8_t v_res_560_; lean_object* v_r_561_; 
v_res_560_ = lp_vsr_x2dveil_Smoke_elect_do___redArg___lam__0(v_x_559_);
lean_dec(v_x_559_);
v_r_561_ = lean_box(v_res_560_);
return v_r_561_;
}
}
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_elect_do___redArg___lam__4(lean_object* v_setIn_562_, lean_object* v___x_563_, lean_object* v___x_564_, lean_object* v___y_565_, lean_object* v___y_566_){
_start:
{
lean_object* v___x_567_; lean_object* v___x_568_; lean_object* v___x_569_; lean_object* v___x_570_; 
v___x_567_ = lean_apply_2(v_setIn_562_, v___x_563_, v___y_566_);
v___x_568_ = lean_alloc_ctor(1, 1, 0);
lean_ctor_set(v___x_568_, 0, v___x_564_);
v___x_569_ = lean_alloc_ctor(0, 2, 0);
lean_ctor_set(v___x_569_, 0, v___x_568_);
lean_ctor_set(v___x_569_, 1, v___x_567_);
v___x_570_ = lean_alloc_ctor(0, 1, 0);
lean_ctor_set(v___x_570_, 0, v___x_569_);
return v___x_570_;
}
}
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_elect_do___redArg___lam__4___boxed(lean_object* v_setIn_571_, lean_object* v___x_572_, lean_object* v___x_573_, lean_object* v___y_574_, lean_object* v___y_575_){
_start:
{
lean_object* v_res_576_; 
v_res_576_ = lp_vsr_x2dveil_Smoke_elect_do___redArg___lam__4(v_setIn_571_, v___x_572_, v___x_573_, v___y_574_, v___y_575_);
lean_dec(v___y_574_);
return v_res_576_;
}
}
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_elect_do___redArg___lam__1(lean_object* v___x_577_, lean_object* v_n_578_, lean_object* v___f_579_, lean_object* v_setIn_580_, lean_object* v___f_581_, lean_object* v_____veil__state_582_){
_start:
{
lean_object* v_set_583_; lean_object* v___x_585_; uint8_t v_isShared_586_; uint8_t v_isSharedCheck_598_; 
v_set_583_ = lean_ctor_get(v___x_577_, 1);
v_isSharedCheck_598_ = !lean_is_exclusive(v___x_577_);
if (v_isSharedCheck_598_ == 0)
{
lean_object* v_unused_599_; 
v_unused_599_ = lean_ctor_get(v___x_577_, 0);
lean_dec(v_unused_599_);
v___x_585_ = v___x_577_;
v_isShared_586_ = v_isSharedCheck_598_;
goto v_resetjp_584_;
}
else
{
lean_inc(v_set_583_);
lean_dec(v___x_577_);
v___x_585_ = lean_box(0);
v_isShared_586_ = v_isSharedCheck_598_;
goto v_resetjp_584_;
}
v_resetjp_584_:
{
lean_object* v___x_587_; lean_object* v___x_588_; lean_object* v___x_590_; 
v___x_587_ = lean_alloc_ctor(1, 1, 0);
lean_ctor_set(v___x_587_, 0, v_n_578_);
v___x_588_ = lean_box(0);
if (v_isShared_586_ == 0)
{
lean_ctor_set(v___x_585_, 1, v___x_588_);
lean_ctor_set(v___x_585_, 0, v___x_587_);
v___x_590_ = v___x_585_;
goto v_reusejp_589_;
}
else
{
lean_object* v_reuseFailAlloc_597_; 
v_reuseFailAlloc_597_ = lean_alloc_ctor(0, 2, 0);
lean_ctor_set(v_reuseFailAlloc_597_, 0, v___x_587_);
lean_ctor_set(v_reuseFailAlloc_597_, 1, v___x_588_);
v___x_590_ = v_reuseFailAlloc_597_;
goto v_reusejp_589_;
}
v_reusejp_589_:
{
lean_object* v___x_591_; lean_object* v___x_592_; lean_object* v___x_593_; lean_object* v___x_594_; lean_object* v___f_595_; lean_object* v___x_596_; 
v___x_591_ = lean_alloc_ctor(0, 2, 0);
lean_ctor_set(v___x_591_, 0, v___x_590_);
lean_ctor_set(v___x_591_, 1, v___f_579_);
v___x_592_ = lean_box(0);
v___x_593_ = lean_alloc_ctor(1, 2, 0);
lean_ctor_set(v___x_593_, 0, v___x_591_);
lean_ctor_set(v___x_593_, 1, v___x_592_);
v___x_594_ = lean_apply_2(v_set_583_, v___x_593_, v_____veil__state_582_);
v___f_595_ = lean_alloc_closure((void*)(lp_vsr_x2dveil_Smoke_elect_do___redArg___lam__4___boxed), 5, 3);
lean_closure_set(v___f_595_, 0, v_setIn_580_);
lean_closure_set(v___f_595_, 1, v___x_594_);
lean_closure_set(v___f_595_, 2, v___x_588_);
v___x_596_ = lean_alloc_ctor(1, 2, 0);
lean_ctor_set(v___x_596_, 0, v___f_595_);
lean_ctor_set(v___x_596_, 1, v___f_581_);
return v___x_596_;
}
}
}
}
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_elect_do___redArg___lam__2(lean_object* v___x_600_, lean_object* v___f_601_, lean_object* v_____r_602_){
_start:
{
lean_object* v___x_603_; 
v___x_603_ = lp_Loom_NonDetT_bind___redArg(v___x_600_, v___f_601_);
return v___x_603_;
}
}
static lean_object* _init_lp_vsr_x2dveil_Smoke_elect_do___redArg___lam__3___closed__0(void){
_start:
{
lean_object* v___x_604_; lean_object* v___x_605_; 
v___x_604_ = lean_unsigned_to_nat(0u);
v___x_605_ = lean_nat_to_int(v___x_604_);
return v___x_605_;
}
}
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_elect_do___redArg___lam__3(lean_object* v_00_u03c7__rep_606_, lean_object* v_n_607_, lean_object* v___f_608_, lean_object* v_setIn_609_, lean_object* v___f_610_, lean_object* v___x_611_, lean_object* v_dec__pred_612_, uint8_t v_____veil__mode_613_, lean_object* v_____veil__state_614_){
_start:
{
lean_object* v___x_615_; lean_object* v___x_616_; lean_object* v___f_617_; lean_object* v___f_618_; lean_object* v___x_619_; lean_object* v___x_620_; uint8_t v___x_621_; lean_object* v___x_622_; lean_object* v___x_623_; 
v___x_615_ = lean_box(0);
v___x_616_ = lean_apply_1(v_00_u03c7__rep_606_, v___x_615_);
v___f_617_ = lean_alloc_closure((void*)(lp_vsr_x2dveil_Smoke_elect_do___redArg___lam__1), 6, 5);
lean_closure_set(v___f_617_, 0, v___x_616_);
lean_closure_set(v___f_617_, 1, v_n_607_);
lean_closure_set(v___f_617_, 2, v___f_608_);
lean_closure_set(v___f_617_, 3, v_setIn_609_);
lean_closure_set(v___f_617_, 4, v___f_610_);
v___f_618_ = lean_alloc_closure((void*)(lp_vsr_x2dveil_Smoke_elect_do___redArg___lam__2), 3, 2);
lean_closure_set(v___f_618_, 0, v___x_611_);
lean_closure_set(v___f_618_, 1, v___f_617_);
v___x_619_ = lean_apply_1(v_dec__pred_612_, v_____veil__state_614_);
v___x_620_ = lean_obj_once(&lp_vsr_x2dveil_Smoke_elect_do___redArg___lam__3___closed__0, &lp_vsr_x2dveil_Smoke_elect_do___redArg___lam__3___closed__0_once, _init_lp_vsr_x2dveil_Smoke_elect_do___redArg___lam__3___closed__0);
v___x_621_ = lean_unbox(v___x_619_);
v___x_622_ = lp_veil_Veil_VeilM_require___redArg(v_____veil__mode_613_, v___x_621_, v___x_620_);
v___x_623_ = lp_Loom_NonDetT_bind___redArg(v___x_622_, v___f_618_);
return v___x_623_;
}
}
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_elect_do___redArg___lam__3___boxed(lean_object* v_00_u03c7__rep_624_, lean_object* v_n_625_, lean_object* v___f_626_, lean_object* v_setIn_627_, lean_object* v___f_628_, lean_object* v___x_629_, lean_object* v_dec__pred_630_, lean_object* v_____veil__mode_631_, lean_object* v_____veil__state_632_){
_start:
{
uint8_t v_____veil__mode_boxed_633_; lean_object* v_res_634_; 
v_____veil__mode_boxed_633_ = lean_unbox(v_____veil__mode_631_);
v_res_634_ = lp_vsr_x2dveil_Smoke_elect_do___redArg___lam__3(v_00_u03c7__rep_624_, v_n_625_, v___f_626_, v_setIn_627_, v___f_628_, v___x_629_, v_dec__pred_630_, v_____veil__mode_boxed_633_, v_____veil__state_632_);
return v_res_634_;
}
}
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_elect_do___redArg___lam__5(lean_object* v_00_u03c3__sub_635_, lean_object* v___f_636_, lean_object* v_00_u03c7__rep_637_, lean_object* v_n_638_, lean_object* v___f_639_, lean_object* v___f_640_, lean_object* v_dec__pred_641_, uint8_t v_____veil__mode_642_, lean_object* v_____veil__theory_643_){
_start:
{
lean_object* v_setIn_644_; lean_object* v_getFrom_645_; lean_object* v___x_647_; uint8_t v_isShared_648_; uint8_t v_isSharedCheck_656_; 
v_setIn_644_ = lean_ctor_get(v_00_u03c3__sub_635_, 0);
v_getFrom_645_ = lean_ctor_get(v_00_u03c3__sub_635_, 1);
v_isSharedCheck_656_ = !lean_is_exclusive(v_00_u03c3__sub_635_);
if (v_isSharedCheck_656_ == 0)
{
v___x_647_ = v_00_u03c3__sub_635_;
v_isShared_648_ = v_isSharedCheck_656_;
goto v_resetjp_646_;
}
else
{
lean_inc(v_getFrom_645_);
lean_inc(v_setIn_644_);
lean_dec(v_00_u03c3__sub_635_);
v___x_647_ = lean_box(0);
v_isShared_648_ = v_isSharedCheck_656_;
goto v_resetjp_646_;
}
v_resetjp_646_:
{
lean_object* v___f_649_; lean_object* v___x_651_; 
v___f_649_ = lean_alloc_closure((void*)(lp_vsr_x2dveil_Smoke_initializer_do___redArg___lam__5___boxed), 3, 1);
lean_closure_set(v___f_649_, 0, v_getFrom_645_);
if (v_isShared_648_ == 0)
{
lean_ctor_set_tag(v___x_647_, 1);
lean_ctor_set(v___x_647_, 1, v___f_636_);
lean_ctor_set(v___x_647_, 0, v___f_649_);
v___x_651_ = v___x_647_;
goto v_reusejp_650_;
}
else
{
lean_object* v_reuseFailAlloc_655_; 
v_reuseFailAlloc_655_ = lean_alloc_ctor(1, 2, 0);
lean_ctor_set(v_reuseFailAlloc_655_, 0, v___f_649_);
lean_ctor_set(v_reuseFailAlloc_655_, 1, v___f_636_);
v___x_651_ = v_reuseFailAlloc_655_;
goto v_reusejp_650_;
}
v_reusejp_650_:
{
lean_object* v___x_652_; lean_object* v___f_653_; lean_object* v___x_654_; 
v___x_652_ = lean_box(v_____veil__mode_642_);
lean_inc_ref(v___x_651_);
v___f_653_ = lean_alloc_closure((void*)(lp_vsr_x2dveil_Smoke_elect_do___redArg___lam__3___boxed), 9, 8);
lean_closure_set(v___f_653_, 0, v_00_u03c7__rep_637_);
lean_closure_set(v___f_653_, 1, v_n_638_);
lean_closure_set(v___f_653_, 2, v___f_639_);
lean_closure_set(v___f_653_, 3, v_setIn_644_);
lean_closure_set(v___f_653_, 4, v___f_640_);
lean_closure_set(v___f_653_, 5, v___x_651_);
lean_closure_set(v___f_653_, 6, v_dec__pred_641_);
lean_closure_set(v___f_653_, 7, v___x_652_);
v___x_654_ = lp_Loom_NonDetT_bind___redArg(v___x_651_, v___f_653_);
return v___x_654_;
}
}
}
}
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_elect_do___redArg___lam__5___boxed(lean_object* v_00_u03c3__sub_657_, lean_object* v___f_658_, lean_object* v_00_u03c7__rep_659_, lean_object* v_n_660_, lean_object* v___f_661_, lean_object* v___f_662_, lean_object* v_dec__pred_663_, lean_object* v_____veil__mode_664_, lean_object* v_____veil__theory_665_){
_start:
{
uint8_t v_____veil__mode_boxed_666_; lean_object* v_res_667_; 
v_____veil__mode_boxed_666_ = lean_unbox(v_____veil__mode_664_);
v_res_667_ = lp_vsr_x2dveil_Smoke_elect_do___redArg___lam__5(v_00_u03c3__sub_657_, v___f_658_, v_00_u03c7__rep_659_, v_n_660_, v___f_661_, v___f_662_, v_dec__pred_663_, v_____veil__mode_boxed_666_, v_____veil__theory_665_);
return v_res_667_;
}
}
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_elect_do___redArg(uint8_t v_____veil__mode_669_, lean_object* v_00_u03c7__rep_670_, lean_object* v_00_u03c3__sub_671_, lean_object* v_00_u03c1__sub_672_, lean_object* v_dec__pred_673_, lean_object* v_n_674_){
_start:
{
lean_object* v___f_675_; lean_object* v___f_676_; lean_object* v___f_677_; lean_object* v___x_678_; lean_object* v___f_679_; lean_object* v___f_680_; lean_object* v___f_681_; lean_object* v___x_682_; lean_object* v___x_683_; 
v___f_675_ = ((lean_object*)(lp_vsr_x2dveil_Smoke_elect_do___redArg___closed__0));
v___f_676_ = ((lean_object*)(lp_vsr_x2dveil_Smoke_initializer_do___redArg___closed__1));
v___f_677_ = ((lean_object*)(lp_vsr_x2dveil_Smoke_initializer_do___redArg___closed__0));
v___x_678_ = lean_box(v_____veil__mode_669_);
v___f_679_ = lean_alloc_closure((void*)(lp_vsr_x2dveil_Smoke_elect_do___redArg___lam__5___boxed), 9, 8);
lean_closure_set(v___f_679_, 0, v_00_u03c3__sub_671_);
lean_closure_set(v___f_679_, 1, v___f_677_);
lean_closure_set(v___f_679_, 2, v_00_u03c7__rep_670_);
lean_closure_set(v___f_679_, 3, v_n_674_);
lean_closure_set(v___f_679_, 4, v___f_675_);
lean_closure_set(v___f_679_, 5, v___f_676_);
lean_closure_set(v___f_679_, 6, v_dec__pred_673_);
lean_closure_set(v___f_679_, 7, v___x_678_);
v___f_680_ = ((lean_object*)(lp_vsr_x2dveil_Smoke_initializer_do___redArg___closed__3));
v___f_681_ = lean_alloc_closure((void*)(lp_vsr_x2dveil_Smoke_initializer_do___redArg___lam__8), 3, 1);
lean_closure_set(v___f_681_, 0, v_00_u03c1__sub_672_);
v___x_682_ = lean_alloc_ctor(1, 2, 0);
lean_ctor_set(v___x_682_, 0, v___f_681_);
lean_ctor_set(v___x_682_, 1, v___f_680_);
v___x_683_ = lp_Loom_NonDetT_bind___redArg(v___x_682_, v___f_679_);
return v___x_683_;
}
}
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_elect_do___redArg___boxed(lean_object* v_____veil__mode_684_, lean_object* v_00_u03c7__rep_685_, lean_object* v_00_u03c3__sub_686_, lean_object* v_00_u03c1__sub_687_, lean_object* v_dec__pred_688_, lean_object* v_n_689_){
_start:
{
uint8_t v_____veil__mode_boxed_690_; lean_object* v_res_691_; 
v_____veil__mode_boxed_690_ = lean_unbox(v_____veil__mode_684_);
v_res_691_ = lp_vsr_x2dveil_Smoke_elect_do___redArg(v_____veil__mode_boxed_690_, v_00_u03c7__rep_685_, v_00_u03c3__sub_686_, v_00_u03c1__sub_687_, v_dec__pred_688_, v_n_689_);
return v_res_691_;
}
}
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_elect_do(uint8_t v_____veil__mode_692_, lean_object* v_00_u03c1_693_, lean_object* v_00_u03c3_694_, lean_object* v_node_695_, lean_object* v_node__dec__eq_696_, lean_object* v_node__inhabited_697_, lean_object* v_00_u03c7_698_, lean_object* v_00_u03c7__rep_699_, lean_object* v_00_u03c7__rep__lawful_700_, lean_object* v_00_u03c3__sub_701_, lean_object* v_00_u03c1__sub_702_, lean_object* v_dec__pred_703_, lean_object* v_n_704_){
_start:
{
lean_object* v___x_705_; 
v___x_705_ = lp_vsr_x2dveil_Smoke_elect_do___redArg(v_____veil__mode_692_, v_00_u03c7__rep_699_, v_00_u03c3__sub_701_, v_00_u03c1__sub_702_, v_dec__pred_703_, v_n_704_);
return v___x_705_;
}
}
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_elect_do___boxed(lean_object* v_____veil__mode_706_, lean_object* v_00_u03c1_707_, lean_object* v_00_u03c3_708_, lean_object* v_node_709_, lean_object* v_node__dec__eq_710_, lean_object* v_node__inhabited_711_, lean_object* v_00_u03c7_712_, lean_object* v_00_u03c7__rep_713_, lean_object* v_00_u03c7__rep__lawful_714_, lean_object* v_00_u03c3__sub_715_, lean_object* v_00_u03c1__sub_716_, lean_object* v_dec__pred_717_, lean_object* v_n_718_){
_start:
{
uint8_t v_____veil__mode_boxed_719_; lean_object* v_res_720_; 
v_____veil__mode_boxed_719_ = lean_unbox(v_____veil__mode_706_);
v_res_720_ = lp_vsr_x2dveil_Smoke_elect_do(v_____veil__mode_boxed_719_, v_00_u03c1_707_, v_00_u03c3_708_, v_node_709_, v_node__dec__eq_710_, v_node__inhabited_711_, v_00_u03c7_712_, v_00_u03c7__rep_713_, v_00_u03c7__rep__lawful_714_, v_00_u03c3__sub_715_, v_00_u03c1__sub_716_, v_dec__pred_717_, v_n_718_);
lean_dec(v_node__inhabited_711_);
lean_dec_ref(v_node__dec__eq_710_);
return v_res_720_;
}
}
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_elect___redArg___lam__7(lean_object* v_00_u03c7__rep_721_, lean_object* v_n_722_, lean_object* v___f_723_, lean_object* v_setIn_724_, lean_object* v___f_725_, lean_object* v___x_726_, lean_object* v_dec__pred_727_, lean_object* v_____veil__state_728_){
_start:
{
lean_object* v___x_729_; lean_object* v___x_730_; lean_object* v___f_731_; lean_object* v___f_732_; uint8_t v___x_733_; lean_object* v___x_734_; lean_object* v___x_735_; uint8_t v___x_736_; lean_object* v___x_737_; lean_object* v___x_738_; 
v___x_729_ = lean_box(0);
v___x_730_ = lean_apply_1(v_00_u03c7__rep_721_, v___x_729_);
v___f_731_ = lean_alloc_closure((void*)(lp_vsr_x2dveil_Smoke_elect_do___redArg___lam__1), 6, 5);
lean_closure_set(v___f_731_, 0, v___x_730_);
lean_closure_set(v___f_731_, 1, v_n_722_);
lean_closure_set(v___f_731_, 2, v___f_723_);
lean_closure_set(v___f_731_, 3, v_setIn_724_);
lean_closure_set(v___f_731_, 4, v___f_725_);
v___f_732_ = lean_alloc_closure((void*)(lp_vsr_x2dveil_Smoke_elect_do___redArg___lam__2), 3, 2);
lean_closure_set(v___f_732_, 0, v___x_726_);
lean_closure_set(v___f_732_, 1, v___f_731_);
v___x_733_ = 0;
v___x_734_ = lean_apply_1(v_dec__pred_727_, v_____veil__state_728_);
v___x_735_ = lean_obj_once(&lp_vsr_x2dveil_Smoke_elect_do___redArg___lam__3___closed__0, &lp_vsr_x2dveil_Smoke_elect_do___redArg___lam__3___closed__0_once, _init_lp_vsr_x2dveil_Smoke_elect_do___redArg___lam__3___closed__0);
v___x_736_ = lean_unbox(v___x_734_);
v___x_737_ = lp_veil_Veil_VeilM_require___redArg(v___x_733_, v___x_736_, v___x_735_);
v___x_738_ = lp_Loom_NonDetT_bind___redArg(v___x_737_, v___f_732_);
return v___x_738_;
}
}
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_elect___redArg___lam__0(lean_object* v_00_u03c3__sub_739_, lean_object* v___f_740_, lean_object* v_00_u03c7__rep_741_, lean_object* v_n_742_, lean_object* v___f_743_, lean_object* v___f_744_, lean_object* v_dec__pred_745_, lean_object* v_____veil__theory_746_){
_start:
{
lean_object* v_setIn_747_; lean_object* v_getFrom_748_; lean_object* v___x_750_; uint8_t v_isShared_751_; uint8_t v_isSharedCheck_758_; 
v_setIn_747_ = lean_ctor_get(v_00_u03c3__sub_739_, 0);
v_getFrom_748_ = lean_ctor_get(v_00_u03c3__sub_739_, 1);
v_isSharedCheck_758_ = !lean_is_exclusive(v_00_u03c3__sub_739_);
if (v_isSharedCheck_758_ == 0)
{
v___x_750_ = v_00_u03c3__sub_739_;
v_isShared_751_ = v_isSharedCheck_758_;
goto v_resetjp_749_;
}
else
{
lean_inc(v_getFrom_748_);
lean_inc(v_setIn_747_);
lean_dec(v_00_u03c3__sub_739_);
v___x_750_ = lean_box(0);
v_isShared_751_ = v_isSharedCheck_758_;
goto v_resetjp_749_;
}
v_resetjp_749_:
{
lean_object* v___f_752_; lean_object* v___x_754_; 
v___f_752_ = lean_alloc_closure((void*)(lp_vsr_x2dveil_Smoke_initializer_do___redArg___lam__5___boxed), 3, 1);
lean_closure_set(v___f_752_, 0, v_getFrom_748_);
if (v_isShared_751_ == 0)
{
lean_ctor_set_tag(v___x_750_, 1);
lean_ctor_set(v___x_750_, 1, v___f_740_);
lean_ctor_set(v___x_750_, 0, v___f_752_);
v___x_754_ = v___x_750_;
goto v_reusejp_753_;
}
else
{
lean_object* v_reuseFailAlloc_757_; 
v_reuseFailAlloc_757_ = lean_alloc_ctor(1, 2, 0);
lean_ctor_set(v_reuseFailAlloc_757_, 0, v___f_752_);
lean_ctor_set(v_reuseFailAlloc_757_, 1, v___f_740_);
v___x_754_ = v_reuseFailAlloc_757_;
goto v_reusejp_753_;
}
v_reusejp_753_:
{
lean_object* v___f_755_; lean_object* v___x_756_; 
lean_inc_ref(v___x_754_);
v___f_755_ = lean_alloc_closure((void*)(lp_vsr_x2dveil_Smoke_elect___redArg___lam__7), 8, 7);
lean_closure_set(v___f_755_, 0, v_00_u03c7__rep_741_);
lean_closure_set(v___f_755_, 1, v_n_742_);
lean_closure_set(v___f_755_, 2, v___f_743_);
lean_closure_set(v___f_755_, 3, v_setIn_747_);
lean_closure_set(v___f_755_, 4, v___f_744_);
lean_closure_set(v___f_755_, 5, v___x_754_);
lean_closure_set(v___f_755_, 6, v_dec__pred_745_);
v___x_756_ = lp_Loom_NonDetT_bind___redArg(v___x_754_, v___f_755_);
return v___x_756_;
}
}
}
}
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_elect___redArg(lean_object* v_00_u03c7__rep_759_, lean_object* v_00_u03c3__sub_760_, lean_object* v_00_u03c1__sub_761_, lean_object* v_dec__pred_762_, lean_object* v_n_763_){
_start:
{
lean_object* v___f_764_; lean_object* v___f_765_; lean_object* v___f_766_; lean_object* v___f_767_; lean_object* v___f_768_; lean_object* v___f_769_; lean_object* v___x_770_; lean_object* v___x_771_; 
v___f_764_ = ((lean_object*)(lp_vsr_x2dveil_Smoke_elect_do___redArg___closed__0));
v___f_765_ = ((lean_object*)(lp_vsr_x2dveil_Smoke_initializer_do___redArg___closed__1));
v___f_766_ = ((lean_object*)(lp_vsr_x2dveil_Smoke_initializer_do___redArg___closed__0));
v___f_767_ = lean_alloc_closure((void*)(lp_vsr_x2dveil_Smoke_elect___redArg___lam__0), 8, 7);
lean_closure_set(v___f_767_, 0, v_00_u03c3__sub_760_);
lean_closure_set(v___f_767_, 1, v___f_766_);
lean_closure_set(v___f_767_, 2, v_00_u03c7__rep_759_);
lean_closure_set(v___f_767_, 3, v_n_763_);
lean_closure_set(v___f_767_, 4, v___f_764_);
lean_closure_set(v___f_767_, 5, v___f_765_);
lean_closure_set(v___f_767_, 6, v_dec__pred_762_);
v___f_768_ = ((lean_object*)(lp_vsr_x2dveil_Smoke_initializer_do___redArg___closed__3));
v___f_769_ = lean_alloc_closure((void*)(lp_vsr_x2dveil_Smoke_initializer_do___redArg___lam__8), 3, 1);
lean_closure_set(v___f_769_, 0, v_00_u03c1__sub_761_);
v___x_770_ = lean_alloc_ctor(1, 2, 0);
lean_ctor_set(v___x_770_, 0, v___f_769_);
lean_ctor_set(v___x_770_, 1, v___f_768_);
v___x_771_ = lp_Loom_NonDetT_bind___redArg(v___x_770_, v___f_767_);
return v___x_771_;
}
}
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_elect(lean_object* v_00_u03c1_772_, lean_object* v_00_u03c3_773_, lean_object* v_node_774_, lean_object* v_node__dec__eq_775_, lean_object* v_node__inhabited_776_, lean_object* v_00_u03c7_777_, lean_object* v_00_u03c7__rep_778_, lean_object* v_00_u03c7__rep__lawful_779_, lean_object* v_00_u03c3__sub_780_, lean_object* v_00_u03c1__sub_781_, lean_object* v_dec__pred_782_, lean_object* v_n_783_){
_start:
{
lean_object* v___x_784_; 
v___x_784_ = lp_vsr_x2dveil_Smoke_elect___redArg(v_00_u03c7__rep_778_, v_00_u03c3__sub_780_, v_00_u03c1__sub_781_, v_dec__pred_782_, v_n_783_);
return v___x_784_;
}
}
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_elect___boxed(lean_object* v_00_u03c1_785_, lean_object* v_00_u03c3_786_, lean_object* v_node_787_, lean_object* v_node__dec__eq_788_, lean_object* v_node__inhabited_789_, lean_object* v_00_u03c7_790_, lean_object* v_00_u03c7__rep_791_, lean_object* v_00_u03c7__rep__lawful_792_, lean_object* v_00_u03c3__sub_793_, lean_object* v_00_u03c1__sub_794_, lean_object* v_dec__pred_795_, lean_object* v_n_796_){
_start:
{
lean_object* v_res_797_; 
v_res_797_ = lp_vsr_x2dveil_Smoke_elect(v_00_u03c1_785_, v_00_u03c3_786_, v_node_787_, v_node__dec__eq_788_, v_node__inhabited_789_, v_00_u03c7_790_, v_00_u03c7__rep_791_, v_00_u03c7__rep__lawful_792_, v_00_u03c3__sub_793_, v_00_u03c1__sub_794_, v_dec__pred_795_, v_n_796_);
lean_dec(v_node__inhabited_789_);
lean_dec_ref(v_node__dec__eq_788_);
return v_res_797_;
}
}
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_elect_ext___redArg___lam__9(lean_object* v_00_u03c7__rep_798_, lean_object* v_n_799_, lean_object* v___f_800_, lean_object* v_setIn_801_, lean_object* v___f_802_, lean_object* v___x_803_, lean_object* v_dec__pred_804_, uint8_t v___x_805_, lean_object* v_____veil__state_806_){
_start:
{
lean_object* v___x_807_; lean_object* v___x_808_; lean_object* v___f_809_; lean_object* v___f_810_; lean_object* v___x_811_; lean_object* v___x_812_; uint8_t v___x_813_; lean_object* v___x_814_; lean_object* v___x_815_; 
v___x_807_ = lean_box(0);
v___x_808_ = lean_apply_1(v_00_u03c7__rep_798_, v___x_807_);
v___f_809_ = lean_alloc_closure((void*)(lp_vsr_x2dveil_Smoke_elect_do___redArg___lam__1), 6, 5);
lean_closure_set(v___f_809_, 0, v___x_808_);
lean_closure_set(v___f_809_, 1, v_n_799_);
lean_closure_set(v___f_809_, 2, v___f_800_);
lean_closure_set(v___f_809_, 3, v_setIn_801_);
lean_closure_set(v___f_809_, 4, v___f_802_);
v___f_810_ = lean_alloc_closure((void*)(lp_vsr_x2dveil_Smoke_elect_do___redArg___lam__2), 3, 2);
lean_closure_set(v___f_810_, 0, v___x_803_);
lean_closure_set(v___f_810_, 1, v___f_809_);
v___x_811_ = lean_apply_1(v_dec__pred_804_, v_____veil__state_806_);
v___x_812_ = lean_obj_once(&lp_vsr_x2dveil_Smoke_elect_do___redArg___lam__3___closed__0, &lp_vsr_x2dveil_Smoke_elect_do___redArg___lam__3___closed__0_once, _init_lp_vsr_x2dveil_Smoke_elect_do___redArg___lam__3___closed__0);
v___x_813_ = lean_unbox(v___x_811_);
v___x_814_ = lp_veil_Veil_VeilM_require___redArg(v___x_805_, v___x_813_, v___x_812_);
v___x_815_ = lp_Loom_NonDetT_bind___redArg(v___x_814_, v___f_810_);
return v___x_815_;
}
}
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_elect_ext___redArg___lam__9___boxed(lean_object* v_00_u03c7__rep_816_, lean_object* v_n_817_, lean_object* v___f_818_, lean_object* v_setIn_819_, lean_object* v___f_820_, lean_object* v___x_821_, lean_object* v_dec__pred_822_, lean_object* v___x_823_, lean_object* v_____veil__state_824_){
_start:
{
uint8_t v___x_2306__boxed_825_; lean_object* v_res_826_; 
v___x_2306__boxed_825_ = lean_unbox(v___x_823_);
v_res_826_ = lp_vsr_x2dveil_Smoke_elect_ext___redArg___lam__9(v_00_u03c7__rep_816_, v_n_817_, v___f_818_, v_setIn_819_, v___f_820_, v___x_821_, v_dec__pred_822_, v___x_2306__boxed_825_, v_____veil__state_824_);
return v_res_826_;
}
}
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_elect_ext___redArg___lam__0(lean_object* v_00_u03c3__sub_827_, lean_object* v___f_828_, lean_object* v_00_u03c7__rep_829_, lean_object* v_n_830_, lean_object* v___f_831_, lean_object* v___f_832_, lean_object* v_dec__pred_833_, uint8_t v___x_834_, lean_object* v_____veil__theory_835_){
_start:
{
lean_object* v_setIn_836_; lean_object* v_getFrom_837_; lean_object* v___x_839_; uint8_t v_isShared_840_; uint8_t v_isSharedCheck_848_; 
v_setIn_836_ = lean_ctor_get(v_00_u03c3__sub_827_, 0);
v_getFrom_837_ = lean_ctor_get(v_00_u03c3__sub_827_, 1);
v_isSharedCheck_848_ = !lean_is_exclusive(v_00_u03c3__sub_827_);
if (v_isSharedCheck_848_ == 0)
{
v___x_839_ = v_00_u03c3__sub_827_;
v_isShared_840_ = v_isSharedCheck_848_;
goto v_resetjp_838_;
}
else
{
lean_inc(v_getFrom_837_);
lean_inc(v_setIn_836_);
lean_dec(v_00_u03c3__sub_827_);
v___x_839_ = lean_box(0);
v_isShared_840_ = v_isSharedCheck_848_;
goto v_resetjp_838_;
}
v_resetjp_838_:
{
lean_object* v___f_841_; lean_object* v___x_843_; 
v___f_841_ = lean_alloc_closure((void*)(lp_vsr_x2dveil_Smoke_initializer_do___redArg___lam__5___boxed), 3, 1);
lean_closure_set(v___f_841_, 0, v_getFrom_837_);
if (v_isShared_840_ == 0)
{
lean_ctor_set_tag(v___x_839_, 1);
lean_ctor_set(v___x_839_, 1, v___f_828_);
lean_ctor_set(v___x_839_, 0, v___f_841_);
v___x_843_ = v___x_839_;
goto v_reusejp_842_;
}
else
{
lean_object* v_reuseFailAlloc_847_; 
v_reuseFailAlloc_847_ = lean_alloc_ctor(1, 2, 0);
lean_ctor_set(v_reuseFailAlloc_847_, 0, v___f_841_);
lean_ctor_set(v_reuseFailAlloc_847_, 1, v___f_828_);
v___x_843_ = v_reuseFailAlloc_847_;
goto v_reusejp_842_;
}
v_reusejp_842_:
{
lean_object* v___x_844_; lean_object* v___f_845_; lean_object* v___x_846_; 
v___x_844_ = lean_box(v___x_834_);
lean_inc_ref(v___x_843_);
v___f_845_ = lean_alloc_closure((void*)(lp_vsr_x2dveil_Smoke_elect_ext___redArg___lam__9___boxed), 9, 8);
lean_closure_set(v___f_845_, 0, v_00_u03c7__rep_829_);
lean_closure_set(v___f_845_, 1, v_n_830_);
lean_closure_set(v___f_845_, 2, v___f_831_);
lean_closure_set(v___f_845_, 3, v_setIn_836_);
lean_closure_set(v___f_845_, 4, v___f_832_);
lean_closure_set(v___f_845_, 5, v___x_843_);
lean_closure_set(v___f_845_, 6, v_dec__pred_833_);
lean_closure_set(v___f_845_, 7, v___x_844_);
v___x_846_ = lp_Loom_NonDetT_bind___redArg(v___x_843_, v___f_845_);
return v___x_846_;
}
}
}
}
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_elect_ext___redArg___lam__0___boxed(lean_object* v_00_u03c3__sub_849_, lean_object* v___f_850_, lean_object* v_00_u03c7__rep_851_, lean_object* v_n_852_, lean_object* v___f_853_, lean_object* v___f_854_, lean_object* v_dec__pred_855_, lean_object* v___x_856_, lean_object* v_____veil__theory_857_){
_start:
{
uint8_t v___x_2343__boxed_858_; lean_object* v_res_859_; 
v___x_2343__boxed_858_ = lean_unbox(v___x_856_);
v_res_859_ = lp_vsr_x2dveil_Smoke_elect_ext___redArg___lam__0(v_00_u03c3__sub_849_, v___f_850_, v_00_u03c7__rep_851_, v_n_852_, v___f_853_, v___f_854_, v_dec__pred_855_, v___x_2343__boxed_858_, v_____veil__theory_857_);
return v_res_859_;
}
}
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_elect_ext___redArg(lean_object* v_00_u03c7__rep_860_, lean_object* v_00_u03c3__sub_861_, lean_object* v_00_u03c1__sub_862_, lean_object* v_dec__pred_863_, lean_object* v_n_864_){
_start:
{
lean_object* v___f_865_; lean_object* v___f_866_; lean_object* v___f_867_; lean_object* v___f_868_; lean_object* v___f_869_; uint8_t v___x_870_; lean_object* v___x_871_; lean_object* v___f_872_; lean_object* v___x_873_; lean_object* v___x_874_; lean_object* v___x_875_; 
v___f_865_ = lean_alloc_closure((void*)(lp_vsr_x2dveil_Smoke_initializer_do___redArg___lam__8), 3, 1);
lean_closure_set(v___f_865_, 0, v_00_u03c1__sub_862_);
v___f_866_ = ((lean_object*)(lp_vsr_x2dveil_Smoke_elect_do___redArg___closed__0));
v___f_867_ = ((lean_object*)(lp_vsr_x2dveil_Smoke_initializer_do___redArg___closed__1));
v___f_868_ = ((lean_object*)(lp_vsr_x2dveil_Smoke_initializer_do___redArg___closed__0));
v___f_869_ = ((lean_object*)(lp_vsr_x2dveil_Smoke_initializer_do___redArg___closed__3));
v___x_870_ = 1;
v___x_871_ = lean_box(v___x_870_);
v___f_872_ = lean_alloc_closure((void*)(lp_vsr_x2dveil_Smoke_elect_ext___redArg___lam__0___boxed), 9, 8);
lean_closure_set(v___f_872_, 0, v_00_u03c3__sub_861_);
lean_closure_set(v___f_872_, 1, v___f_868_);
lean_closure_set(v___f_872_, 2, v_00_u03c7__rep_860_);
lean_closure_set(v___f_872_, 3, v_n_864_);
lean_closure_set(v___f_872_, 4, v___f_866_);
lean_closure_set(v___f_872_, 5, v___f_867_);
lean_closure_set(v___f_872_, 6, v_dec__pred_863_);
lean_closure_set(v___f_872_, 7, v___x_871_);
v___x_873_ = lean_alloc_ctor(1, 2, 0);
lean_ctor_set(v___x_873_, 0, v___f_865_);
lean_ctor_set(v___x_873_, 1, v___f_869_);
v___x_874_ = lp_Loom_NonDetT_bind___redArg(v___x_873_, v___f_872_);
v___x_875_ = lp_veil_Veil_VeilM_returnUnit___redArg(v___x_874_);
return v___x_875_;
}
}
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_elect_ext(lean_object* v_00_u03c1_876_, lean_object* v_00_u03c3_877_, lean_object* v_node_878_, lean_object* v_node__dec__eq_879_, lean_object* v_node__inhabited_880_, lean_object* v_00_u03c7_881_, lean_object* v_00_u03c7__rep_882_, lean_object* v_00_u03c7__rep__lawful_883_, lean_object* v_00_u03c3__sub_884_, lean_object* v_00_u03c1__sub_885_, lean_object* v_dec__pred_886_, lean_object* v_n_887_){
_start:
{
lean_object* v___x_888_; 
v___x_888_ = lp_vsr_x2dveil_Smoke_elect_ext___redArg(v_00_u03c7__rep_882_, v_00_u03c3__sub_884_, v_00_u03c1__sub_885_, v_dec__pred_886_, v_n_887_);
return v___x_888_;
}
}
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_elect_ext___boxed(lean_object* v_00_u03c1_889_, lean_object* v_00_u03c3_890_, lean_object* v_node_891_, lean_object* v_node__dec__eq_892_, lean_object* v_node__inhabited_893_, lean_object* v_00_u03c7_894_, lean_object* v_00_u03c7__rep_895_, lean_object* v_00_u03c7__rep__lawful_896_, lean_object* v_00_u03c3__sub_897_, lean_object* v_00_u03c1__sub_898_, lean_object* v_dec__pred_899_, lean_object* v_n_900_){
_start:
{
lean_object* v_res_901_; 
v_res_901_ = lp_vsr_x2dveil_Smoke_elect_ext(v_00_u03c1_889_, v_00_u03c3_890_, v_node_891_, v_node__dec__eq_892_, v_node__inhabited_893_, v_00_u03c7_894_, v_00_u03c7__rep_895_, v_00_u03c7__rep__lawful_896_, v_00_u03c3__sub_897_, v_00_u03c1__sub_898_, v_dec__pred_899_, v_n_900_);
lean_dec(v_node__inhabited_893_);
lean_dec_ref(v_node__dec__eq_892_);
return v_res_901_;
}
}
static lean_object* _init_lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__127___closed__13(void){
_start:
{
lean_object* v___x_927_; lean_object* v___x_928_; 
v___x_927_ = ((lean_object*)(lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__127___closed__11));
v___x_928_ = l_Lean_mkAtom(v___x_927_);
return v___x_928_;
}
}
static lean_object* _init_lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__127___closed__14(void){
_start:
{
lean_object* v___x_929_; lean_object* v___x_930_; lean_object* v___x_931_; 
v___x_929_ = lean_obj_once(&lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__127___closed__13, &lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__127___closed__13_once, _init_lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__127___closed__13);
v___x_930_ = ((lean_object*)(lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__127___closed__5));
v___x_931_ = lean_array_push(v___x_930_, v___x_929_);
return v___x_931_;
}
}
static lean_object* _init_lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__127___closed__15(void){
_start:
{
lean_object* v___x_932_; lean_object* v___x_933_; lean_object* v___x_934_; lean_object* v___x_935_; 
v___x_932_ = lean_obj_once(&lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__127___closed__14, &lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__127___closed__14_once, _init_lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__127___closed__14);
v___x_933_ = ((lean_object*)(lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__127___closed__12));
v___x_934_ = lean_box(2);
v___x_935_ = lean_alloc_ctor(1, 3, 0);
lean_ctor_set(v___x_935_, 0, v___x_934_);
lean_ctor_set(v___x_935_, 1, v___x_933_);
lean_ctor_set(v___x_935_, 2, v___x_932_);
return v___x_935_;
}
}
static lean_object* _init_lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__127___closed__16(void){
_start:
{
lean_object* v___x_936_; lean_object* v___x_937_; lean_object* v___x_938_; 
v___x_936_ = lean_obj_once(&lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__127___closed__15, &lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__127___closed__15_once, _init_lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__127___closed__15);
v___x_937_ = ((lean_object*)(lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__127___closed__5));
v___x_938_ = lean_array_push(v___x_937_, v___x_936_);
return v___x_938_;
}
}
static lean_object* _init_lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__127___closed__17(void){
_start:
{
lean_object* v___x_939_; lean_object* v___x_940_; lean_object* v___x_941_; lean_object* v___x_942_; 
v___x_939_ = lean_obj_once(&lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__127___closed__16, &lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__127___closed__16_once, _init_lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__127___closed__16);
v___x_940_ = ((lean_object*)(lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__127___closed__9));
v___x_941_ = lean_box(2);
v___x_942_ = lean_alloc_ctor(1, 3, 0);
lean_ctor_set(v___x_942_, 0, v___x_941_);
lean_ctor_set(v___x_942_, 1, v___x_940_);
lean_ctor_set(v___x_942_, 2, v___x_939_);
return v___x_942_;
}
}
static lean_object* _init_lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__127___closed__18(void){
_start:
{
lean_object* v___x_943_; lean_object* v___x_944_; lean_object* v___x_945_; 
v___x_943_ = lean_obj_once(&lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__127___closed__17, &lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__127___closed__17_once, _init_lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__127___closed__17);
v___x_944_ = ((lean_object*)(lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__127___closed__5));
v___x_945_ = lean_array_push(v___x_944_, v___x_943_);
return v___x_945_;
}
}
static lean_object* _init_lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__127___closed__19(void){
_start:
{
lean_object* v___x_946_; lean_object* v___x_947_; lean_object* v___x_948_; lean_object* v___x_949_; 
v___x_946_ = lean_obj_once(&lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__127___closed__18, &lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__127___closed__18_once, _init_lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__127___closed__18);
v___x_947_ = ((lean_object*)(lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__127___closed__7));
v___x_948_ = lean_box(2);
v___x_949_ = lean_alloc_ctor(1, 3, 0);
lean_ctor_set(v___x_949_, 0, v___x_948_);
lean_ctor_set(v___x_949_, 1, v___x_947_);
lean_ctor_set(v___x_949_, 2, v___x_946_);
return v___x_949_;
}
}
static lean_object* _init_lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__127___closed__20(void){
_start:
{
lean_object* v___x_950_; lean_object* v___x_951_; lean_object* v___x_952_; 
v___x_950_ = lean_obj_once(&lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__127___closed__19, &lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__127___closed__19_once, _init_lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__127___closed__19);
v___x_951_ = ((lean_object*)(lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__127___closed__5));
v___x_952_ = lean_array_push(v___x_951_, v___x_950_);
return v___x_952_;
}
}
static lean_object* _init_lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__127___closed__21(void){
_start:
{
lean_object* v___x_953_; lean_object* v___x_954_; lean_object* v___x_955_; lean_object* v___x_956_; 
v___x_953_ = lean_obj_once(&lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__127___closed__20, &lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__127___closed__20_once, _init_lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__127___closed__20);
v___x_954_ = ((lean_object*)(lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__127___closed__4));
v___x_955_ = lean_box(2);
v___x_956_ = lean_alloc_ctor(1, 3, 0);
lean_ctor_set(v___x_956_, 0, v___x_955_);
lean_ctor_set(v___x_956_, 1, v___x_954_);
lean_ctor_set(v___x_956_, 2, v___x_953_);
return v___x_956_;
}
}
static lean_object* _init_lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__127(void){
_start:
{
lean_object* v___x_957_; 
v___x_957_ = lean_obj_once(&lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__127___closed__21, &lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__127___closed__21_once, _init_lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__127___closed__21);
return v___x_957_;
}
}
static lean_object* _init_lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__129___closed__2(void){
_start:
{
lean_object* v___x_962_; lean_object* v___x_963_; 
v___x_962_ = ((lean_object*)(lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__129___closed__0));
v___x_963_ = l_Lean_mkAtom(v___x_962_);
return v___x_963_;
}
}
static lean_object* _init_lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__129___closed__3(void){
_start:
{
lean_object* v___x_964_; lean_object* v___x_965_; lean_object* v___x_966_; 
v___x_964_ = lean_obj_once(&lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__129___closed__2, &lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__129___closed__2_once, _init_lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__129___closed__2);
v___x_965_ = ((lean_object*)(lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__127___closed__5));
v___x_966_ = lean_array_push(v___x_965_, v___x_964_);
return v___x_966_;
}
}
static lean_object* _init_lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__129___closed__4(void){
_start:
{
lean_object* v___x_967_; lean_object* v___x_968_; lean_object* v___x_969_; lean_object* v___x_970_; 
v___x_967_ = lean_obj_once(&lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__129___closed__3, &lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__129___closed__3_once, _init_lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__129___closed__3);
v___x_968_ = ((lean_object*)(lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__129___closed__1));
v___x_969_ = lean_box(2);
v___x_970_ = lean_alloc_ctor(1, 3, 0);
lean_ctor_set(v___x_970_, 0, v___x_969_);
lean_ctor_set(v___x_970_, 1, v___x_968_);
lean_ctor_set(v___x_970_, 2, v___x_967_);
return v___x_970_;
}
}
static lean_object* _init_lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__129___closed__5(void){
_start:
{
lean_object* v___x_971_; lean_object* v___x_972_; lean_object* v___x_973_; 
v___x_971_ = lean_obj_once(&lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__129___closed__4, &lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__129___closed__4_once, _init_lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__129___closed__4);
v___x_972_ = ((lean_object*)(lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__127___closed__5));
v___x_973_ = lean_array_push(v___x_972_, v___x_971_);
return v___x_973_;
}
}
static lean_object* _init_lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__129___closed__6(void){
_start:
{
lean_object* v___x_974_; lean_object* v___x_975_; lean_object* v___x_976_; lean_object* v___x_977_; 
v___x_974_ = lean_obj_once(&lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__129___closed__5, &lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__129___closed__5_once, _init_lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__129___closed__5);
v___x_975_ = ((lean_object*)(lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__127___closed__9));
v___x_976_ = lean_box(2);
v___x_977_ = lean_alloc_ctor(1, 3, 0);
lean_ctor_set(v___x_977_, 0, v___x_976_);
lean_ctor_set(v___x_977_, 1, v___x_975_);
lean_ctor_set(v___x_977_, 2, v___x_974_);
return v___x_977_;
}
}
static lean_object* _init_lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__129___closed__7(void){
_start:
{
lean_object* v___x_978_; lean_object* v___x_979_; lean_object* v___x_980_; 
v___x_978_ = lean_obj_once(&lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__129___closed__6, &lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__129___closed__6_once, _init_lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__129___closed__6);
v___x_979_ = ((lean_object*)(lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__127___closed__5));
v___x_980_ = lean_array_push(v___x_979_, v___x_978_);
return v___x_980_;
}
}
static lean_object* _init_lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__129___closed__8(void){
_start:
{
lean_object* v___x_981_; lean_object* v___x_982_; lean_object* v___x_983_; lean_object* v___x_984_; 
v___x_981_ = lean_obj_once(&lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__129___closed__7, &lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__129___closed__7_once, _init_lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__129___closed__7);
v___x_982_ = ((lean_object*)(lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__127___closed__7));
v___x_983_ = lean_box(2);
v___x_984_ = lean_alloc_ctor(1, 3, 0);
lean_ctor_set(v___x_984_, 0, v___x_983_);
lean_ctor_set(v___x_984_, 1, v___x_982_);
lean_ctor_set(v___x_984_, 2, v___x_981_);
return v___x_984_;
}
}
static lean_object* _init_lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__129___closed__9(void){
_start:
{
lean_object* v___x_985_; lean_object* v___x_986_; lean_object* v___x_987_; 
v___x_985_ = lean_obj_once(&lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__129___closed__8, &lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__129___closed__8_once, _init_lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__129___closed__8);
v___x_986_ = ((lean_object*)(lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__127___closed__5));
v___x_987_ = lean_array_push(v___x_986_, v___x_985_);
return v___x_987_;
}
}
static lean_object* _init_lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__129___closed__10(void){
_start:
{
lean_object* v___x_988_; lean_object* v___x_989_; lean_object* v___x_990_; lean_object* v___x_991_; 
v___x_988_ = lean_obj_once(&lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__129___closed__9, &lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__129___closed__9_once, _init_lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__129___closed__9);
v___x_989_ = ((lean_object*)(lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__127___closed__4));
v___x_990_ = lean_box(2);
v___x_991_ = lean_alloc_ctor(1, 3, 0);
lean_ctor_set(v___x_991_, 0, v___x_990_);
lean_ctor_set(v___x_991_, 1, v___x_989_);
lean_ctor_set(v___x_991_, 2, v___x_988_);
return v___x_991_;
}
}
static lean_object* _init_lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__129(void){
_start:
{
lean_object* v___x_992_; 
v___x_992_ = lean_obj_once(&lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__129___closed__10, &lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__129___closed__10_once, _init_lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__129___closed__10);
return v___x_992_;
}
}
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instLocalRPropOne(lean_object* v_00_u03c1_993_, lean_object* v_00_u03c3_994_, lean_object* v_node_995_, lean_object* v_node__dec__eq_996_, lean_object* v_node__inhabited_997_, lean_object* v_00_u03c7_998_, lean_object* v_00_u03c7__rep_999_, lean_object* v_00_u03c7__rep__lawful_1000_, lean_object* v_00_u03c3__sub_1001_, lean_object* v_00_u03c1__sub_1002_){
_start:
{
lean_object* v___x_1003_; 
v___x_1003_ = lean_box(0);
return v___x_1003_;
}
}
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instLocalRPropOne___boxed(lean_object* v_00_u03c1_1004_, lean_object* v_00_u03c3_1005_, lean_object* v_node_1006_, lean_object* v_node__dec__eq_1007_, lean_object* v_node__inhabited_1008_, lean_object* v_00_u03c7_1009_, lean_object* v_00_u03c7__rep_1010_, lean_object* v_00_u03c7__rep__lawful_1011_, lean_object* v_00_u03c3__sub_1012_, lean_object* v_00_u03c1__sub_1013_){
_start:
{
lean_object* v_res_1014_; 
v_res_1014_ = lp_vsr_x2dveil_Smoke_instLocalRPropOne(v_00_u03c1_1004_, v_00_u03c3_1005_, v_node_1006_, v_node__dec__eq_1007_, v_node__inhabited_1008_, v_00_u03c7_1009_, v_00_u03c7__rep_1010_, v_00_u03c7__rep__lawful_1011_, v_00_u03c3__sub_1012_, v_00_u03c1__sub_1013_);
lean_dec_ref(v_00_u03c1__sub_1013_);
lean_dec_ref(v_00_u03c3__sub_1012_);
lean_dec_ref(v_00_u03c7__rep_1010_);
lean_dec(v_node__inhabited_1008_);
lean_dec_ref(v_node__dec__eq_1007_);
return v_res_1014_;
}
}
LEAN_EXPORT uint8_t lp_vsr_x2dveil_Smoke_instDecidableEqLabel_decEq___redArg(lean_object* v_inst_1015_, lean_object* v_x_1016_, lean_object* v_x_1017_){
_start:
{
lean_object* v___x_1018_; uint8_t v___x_1019_; 
v___x_1018_ = lean_apply_2(v_inst_1015_, v_x_1016_, v_x_1017_);
v___x_1019_ = lean_unbox(v___x_1018_);
return v___x_1019_;
}
}
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instDecidableEqLabel_decEq___redArg___boxed(lean_object* v_inst_1020_, lean_object* v_x_1021_, lean_object* v_x_1022_){
_start:
{
uint8_t v_res_1023_; lean_object* v_r_1024_; 
v_res_1023_ = lp_vsr_x2dveil_Smoke_instDecidableEqLabel_decEq___redArg(v_inst_1020_, v_x_1021_, v_x_1022_);
v_r_1024_ = lean_box(v_res_1023_);
return v_r_1024_;
}
}
LEAN_EXPORT uint8_t lp_vsr_x2dveil_Smoke_instDecidableEqLabel_decEq(lean_object* v_node_1025_, lean_object* v_inst_1026_, lean_object* v_x_1027_, lean_object* v_x_1028_){
_start:
{
lean_object* v___x_1029_; uint8_t v___x_1030_; 
v___x_1029_ = lean_apply_2(v_inst_1026_, v_x_1027_, v_x_1028_);
v___x_1030_ = lean_unbox(v___x_1029_);
return v___x_1030_;
}
}
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instDecidableEqLabel_decEq___boxed(lean_object* v_node_1031_, lean_object* v_inst_1032_, lean_object* v_x_1033_, lean_object* v_x_1034_){
_start:
{
uint8_t v_res_1035_; lean_object* v_r_1036_; 
v_res_1035_ = lp_vsr_x2dveil_Smoke_instDecidableEqLabel_decEq(v_node_1031_, v_inst_1032_, v_x_1033_, v_x_1034_);
v_r_1036_ = lean_box(v_res_1035_);
return v_r_1036_;
}
}
LEAN_EXPORT uint8_t lp_vsr_x2dveil_Smoke_instDecidableEqLabel___redArg(lean_object* v_inst_1037_, lean_object* v_x_1038_, lean_object* v_x_1039_){
_start:
{
lean_object* v___x_1040_; uint8_t v___x_1041_; 
v___x_1040_ = lean_apply_2(v_inst_1037_, v_x_1038_, v_x_1039_);
v___x_1041_ = lean_unbox(v___x_1040_);
return v___x_1041_;
}
}
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instDecidableEqLabel___redArg___boxed(lean_object* v_inst_1042_, lean_object* v_x_1043_, lean_object* v_x_1044_){
_start:
{
uint8_t v_res_1045_; lean_object* v_r_1046_; 
v_res_1045_ = lp_vsr_x2dveil_Smoke_instDecidableEqLabel___redArg(v_inst_1042_, v_x_1043_, v_x_1044_);
v_r_1046_ = lean_box(v_res_1045_);
return v_r_1046_;
}
}
LEAN_EXPORT uint8_t lp_vsr_x2dveil_Smoke_instDecidableEqLabel(lean_object* v_node_1047_, lean_object* v_inst_1048_, lean_object* v_x_1049_, lean_object* v_x_1050_){
_start:
{
lean_object* v___x_1051_; uint8_t v___x_1052_; 
v___x_1051_ = lean_apply_2(v_inst_1048_, v_x_1049_, v_x_1050_);
v___x_1052_ = lean_unbox(v___x_1051_);
return v___x_1052_;
}
}
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instDecidableEqLabel___boxed(lean_object* v_node_1053_, lean_object* v_inst_1054_, lean_object* v_x_1055_, lean_object* v_x_1056_){
_start:
{
uint8_t v_res_1057_; lean_object* v_r_1058_; 
v_res_1057_ = lp_vsr_x2dveil_Smoke_instDecidableEqLabel(v_node_1053_, v_inst_1054_, v_x_1055_, v_x_1056_);
v_r_1058_ = lean_box(v_res_1057_);
return v_r_1058_;
}
}
static lean_object* _init_lp_vsr_x2dveil_Smoke_instReprLabel_repr___redArg___closed__3(void){
_start:
{
lean_object* v___x_1065_; lean_object* v___x_1066_; 
v___x_1065_ = lean_unsigned_to_nat(2u);
v___x_1066_ = lean_nat_to_int(v___x_1065_);
return v___x_1066_;
}
}
static lean_object* _init_lp_vsr_x2dveil_Smoke_instReprLabel_repr___redArg___closed__4(void){
_start:
{
lean_object* v___x_1067_; lean_object* v___x_1068_; 
v___x_1067_ = lean_unsigned_to_nat(1u);
v___x_1068_ = lean_nat_to_int(v___x_1067_);
return v___x_1068_;
}
}
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instReprLabel_repr___redArg(lean_object* v_inst_1069_, lean_object* v_x_1070_, lean_object* v_prec_1071_){
_start:
{
lean_object* v___y_1073_; lean_object* v___x_1082_; uint8_t v___x_1083_; 
v___x_1082_ = lean_unsigned_to_nat(1024u);
v___x_1083_ = lean_nat_dec_le(v___x_1082_, v_prec_1071_);
if (v___x_1083_ == 0)
{
lean_object* v___x_1084_; 
v___x_1084_ = lean_obj_once(&lp_vsr_x2dveil_Smoke_instReprLabel_repr___redArg___closed__3, &lp_vsr_x2dveil_Smoke_instReprLabel_repr___redArg___closed__3_once, _init_lp_vsr_x2dveil_Smoke_instReprLabel_repr___redArg___closed__3);
v___y_1073_ = v___x_1084_;
goto v___jp_1072_;
}
else
{
lean_object* v___x_1085_; 
v___x_1085_ = lean_obj_once(&lp_vsr_x2dveil_Smoke_instReprLabel_repr___redArg___closed__4, &lp_vsr_x2dveil_Smoke_instReprLabel_repr___redArg___closed__4_once, _init_lp_vsr_x2dveil_Smoke_instReprLabel_repr___redArg___closed__4);
v___y_1073_ = v___x_1085_;
goto v___jp_1072_;
}
v___jp_1072_:
{
lean_object* v___x_1074_; lean_object* v___x_1075_; lean_object* v___x_1076_; lean_object* v___x_1077_; lean_object* v___x_1078_; uint8_t v___x_1079_; lean_object* v___x_1080_; lean_object* v___x_1081_; 
v___x_1074_ = ((lean_object*)(lp_vsr_x2dveil_Smoke_instReprLabel_repr___redArg___closed__2));
v___x_1075_ = lean_unsigned_to_nat(1024u);
v___x_1076_ = lean_apply_2(v_inst_1069_, v_x_1070_, v___x_1075_);
v___x_1077_ = lean_alloc_ctor(5, 2, 0);
lean_ctor_set(v___x_1077_, 0, v___x_1074_);
lean_ctor_set(v___x_1077_, 1, v___x_1076_);
lean_inc(v___y_1073_);
v___x_1078_ = lean_alloc_ctor(4, 2, 0);
lean_ctor_set(v___x_1078_, 0, v___y_1073_);
lean_ctor_set(v___x_1078_, 1, v___x_1077_);
v___x_1079_ = 0;
v___x_1080_ = lean_alloc_ctor(6, 1, 1);
lean_ctor_set(v___x_1080_, 0, v___x_1078_);
lean_ctor_set_uint8(v___x_1080_, sizeof(void*)*1, v___x_1079_);
v___x_1081_ = l_Repr_addAppParen(v___x_1080_, v_prec_1071_);
return v___x_1081_;
}
}
}
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instReprLabel_repr___redArg___boxed(lean_object* v_inst_1086_, lean_object* v_x_1087_, lean_object* v_prec_1088_){
_start:
{
lean_object* v_res_1089_; 
v_res_1089_ = lp_vsr_x2dveil_Smoke_instReprLabel_repr___redArg(v_inst_1086_, v_x_1087_, v_prec_1088_);
lean_dec(v_prec_1088_);
return v_res_1089_;
}
}
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instReprLabel_repr(lean_object* v_node_1090_, lean_object* v_inst_1091_, lean_object* v_x_1092_, lean_object* v_prec_1093_){
_start:
{
lean_object* v___x_1094_; 
v___x_1094_ = lp_vsr_x2dveil_Smoke_instReprLabel_repr___redArg(v_inst_1091_, v_x_1092_, v_prec_1093_);
return v___x_1094_;
}
}
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instReprLabel_repr___boxed(lean_object* v_node_1095_, lean_object* v_inst_1096_, lean_object* v_x_1097_, lean_object* v_prec_1098_){
_start:
{
lean_object* v_res_1099_; 
v_res_1099_ = lp_vsr_x2dveil_Smoke_instReprLabel_repr(v_node_1095_, v_inst_1096_, v_x_1097_, v_prec_1098_);
lean_dec(v_prec_1098_);
return v_res_1099_;
}
}
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instReprLabel___redArg(lean_object* v_inst_1100_){
_start:
{
lean_object* v___x_1101_; 
v___x_1101_ = lean_alloc_closure((void*)(lp_vsr_x2dveil_Smoke_instReprLabel_repr___boxed), 4, 2);
lean_closure_set(v___x_1101_, 0, lean_box(0));
lean_closure_set(v___x_1101_, 1, v_inst_1100_);
return v___x_1101_;
}
}
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instReprLabel(lean_object* v_node_1102_, lean_object* v_inst_1103_){
_start:
{
lean_object* v___x_1104_; 
v___x_1104_ = lean_alloc_closure((void*)(lp_vsr_x2dveil_Smoke_instReprLabel_repr___boxed), 4, 2);
lean_closure_set(v___x_1104_, 0, lean_box(0));
lean_closure_set(v___x_1104_, 1, v_inst_1103_);
return v___x_1104_;
}
}
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instToJsonLabel_toJson___redArg(lean_object* v_inst_1107_, lean_object* v_x_1108_){
_start:
{
lean_object* v___x_1109_; lean_object* v___x_1110_; lean_object* v___x_1111_; lean_object* v___x_1112_; lean_object* v___x_1113_; lean_object* v___x_1114_; lean_object* v___x_1115_; lean_object* v___x_1116_; lean_object* v___x_1117_; lean_object* v___x_1118_; 
v___x_1109_ = ((lean_object*)(lp_vsr_x2dveil_Smoke_instToJsonLabel_toJson___redArg___closed__0));
v___x_1110_ = ((lean_object*)(lp_vsr_x2dveil_Smoke_instToJsonLabel_toJson___redArg___closed__1));
v___x_1111_ = lean_apply_1(v_inst_1107_, v_x_1108_);
v___x_1112_ = lean_alloc_ctor(0, 2, 0);
lean_ctor_set(v___x_1112_, 0, v___x_1110_);
lean_ctor_set(v___x_1112_, 1, v___x_1111_);
v___x_1113_ = lean_box(0);
v___x_1114_ = lean_alloc_ctor(1, 2, 0);
lean_ctor_set(v___x_1114_, 0, v___x_1112_);
lean_ctor_set(v___x_1114_, 1, v___x_1113_);
v___x_1115_ = l_Lean_Json_mkObj(v___x_1114_);
lean_dec_ref_known(v___x_1114_, 2);
v___x_1116_ = lean_alloc_ctor(0, 2, 0);
lean_ctor_set(v___x_1116_, 0, v___x_1109_);
lean_ctor_set(v___x_1116_, 1, v___x_1115_);
v___x_1117_ = lean_alloc_ctor(1, 2, 0);
lean_ctor_set(v___x_1117_, 0, v___x_1116_);
lean_ctor_set(v___x_1117_, 1, v___x_1113_);
v___x_1118_ = l_Lean_Json_mkObj(v___x_1117_);
lean_dec_ref_known(v___x_1117_, 2);
return v___x_1118_;
}
}
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instToJsonLabel_toJson(lean_object* v_node_1119_, lean_object* v_inst_1120_, lean_object* v_x_1121_){
_start:
{
lean_object* v___x_1122_; 
v___x_1122_ = lp_vsr_x2dveil_Smoke_instToJsonLabel_toJson___redArg(v_inst_1120_, v_x_1121_);
return v___x_1122_;
}
}
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instToJsonLabel___redArg(lean_object* v_inst_1123_){
_start:
{
lean_object* v___x_1124_; 
v___x_1124_ = lean_alloc_closure((void*)(lp_vsr_x2dveil_Smoke_instToJsonLabel_toJson), 3, 2);
lean_closure_set(v___x_1124_, 0, lean_box(0));
lean_closure_set(v___x_1124_, 1, v_inst_1123_);
return v___x_1124_;
}
}
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instToJsonLabel(lean_object* v_node_1125_, lean_object* v_inst_1126_){
_start:
{
lean_object* v___x_1127_; 
v___x_1127_ = lean_alloc_closure((void*)(lp_vsr_x2dveil_Smoke_instToJsonLabel_toJson), 3, 2);
lean_closure_set(v___x_1127_, 0, lean_box(0));
lean_closure_set(v___x_1127_, 1, v_inst_1126_);
return v___x_1127_;
}
}
LEAN_EXPORT uint64_t lp_vsr_x2dveil_Smoke_instHashableLabel_hash___redArg(lean_object* v_inst_1128_, lean_object* v_x_1129_){
_start:
{
uint64_t v___x_1130_; lean_object* v___x_1131_; uint64_t v___x_1132_; uint64_t v___x_1133_; 
v___x_1130_ = 0ULL;
v___x_1131_ = lean_apply_1(v_inst_1128_, v_x_1129_);
v___x_1132_ = lean_unbox_uint64(v___x_1131_);
lean_dec_ref(v___x_1131_);
v___x_1133_ = lean_uint64_mix_hash(v___x_1130_, v___x_1132_);
return v___x_1133_;
}
}
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instHashableLabel_hash___redArg___boxed(lean_object* v_inst_1134_, lean_object* v_x_1135_){
_start:
{
uint64_t v_res_1136_; lean_object* v_r_1137_; 
v_res_1136_ = lp_vsr_x2dveil_Smoke_instHashableLabel_hash___redArg(v_inst_1134_, v_x_1135_);
v_r_1137_ = lean_box_uint64(v_res_1136_);
return v_r_1137_;
}
}
LEAN_EXPORT uint64_t lp_vsr_x2dveil_Smoke_instHashableLabel_hash(lean_object* v_node_1138_, lean_object* v_inst_1139_, lean_object* v_x_1140_){
_start:
{
uint64_t v___x_1141_; 
v___x_1141_ = lp_vsr_x2dveil_Smoke_instHashableLabel_hash___redArg(v_inst_1139_, v_x_1140_);
return v___x_1141_;
}
}
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instHashableLabel_hash___boxed(lean_object* v_node_1142_, lean_object* v_inst_1143_, lean_object* v_x_1144_){
_start:
{
uint64_t v_res_1145_; lean_object* v_r_1146_; 
v_res_1145_ = lp_vsr_x2dveil_Smoke_instHashableLabel_hash(v_node_1142_, v_inst_1143_, v_x_1144_);
v_r_1146_ = lean_box_uint64(v_res_1145_);
return v_r_1146_;
}
}
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instHashableLabel___redArg(lean_object* v_inst_1147_){
_start:
{
lean_object* v___x_1148_; 
v___x_1148_ = lean_alloc_closure((void*)(lp_vsr_x2dveil_Smoke_instHashableLabel_hash___boxed), 3, 2);
lean_closure_set(v___x_1148_, 0, lean_box(0));
lean_closure_set(v___x_1148_, 1, v_inst_1147_);
return v___x_1148_;
}
}
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instHashableLabel(lean_object* v_node_1149_, lean_object* v_inst_1150_){
_start:
{
lean_object* v___x_1151_; 
v___x_1151_ = lean_alloc_closure((void*)(lp_vsr_x2dveil_Smoke_instHashableLabel_hash___boxed), 3, 2);
lean_closure_set(v___x_1151_, 0, lean_box(0));
lean_closure_set(v___x_1151_, 1, v_inst_1150_);
return v___x_1151_;
}
}
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_Label_proxyTypeEquiv___lam__0(lean_object* v_x_1152_){
_start:
{
lean_inc(v_x_1152_);
return v_x_1152_;
}
}
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_Label_proxyTypeEquiv___lam__0___boxed(lean_object* v_x_1153_){
_start:
{
lean_object* v_res_1154_; 
v_res_1154_ = lp_vsr_x2dveil_Smoke_Label_proxyTypeEquiv___lam__0(v_x_1153_);
lean_dec(v_x_1153_);
return v_res_1154_;
}
}
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_Label_proxyTypeEquiv(lean_object* v_node_1158_){
_start:
{
lean_object* v___x_1159_; 
v___x_1159_ = ((lean_object*)(lp_vsr_x2dveil_Smoke_Label_proxyTypeEquiv___closed__1));
return v___x_1159_;
}
}
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instEnumerationLabel___redArg___lam__0(lean_object* v___x_1160_, lean_object* v___y_1161_){
_start:
{
lean_object* v_toFun_1162_; lean_object* v___x_1163_; 
v_toFun_1162_ = lean_ctor_get(v___x_1160_, 0);
lean_inc(v_toFun_1162_);
lean_dec_ref(v___x_1160_);
v___x_1163_ = lean_apply_1(v_toFun_1162_, v___y_1161_);
return v___x_1163_;
}
}
static lean_object* _init_lp_vsr_x2dveil_Smoke_instEnumerationLabel___redArg___closed__0(void){
_start:
{
lean_object* v___x_1164_; 
v___x_1164_ = lp_vsr_x2dveil_Smoke_Label_proxyTypeEquiv(lean_box(0));
return v___x_1164_;
}
}
static lean_object* _init_lp_vsr_x2dveil_Smoke_instEnumerationLabel___redArg___closed__1(void){
_start:
{
lean_object* v___x_1165_; lean_object* v___f_1166_; 
v___x_1165_ = lean_obj_once(&lp_vsr_x2dveil_Smoke_instEnumerationLabel___redArg___closed__0, &lp_vsr_x2dveil_Smoke_instEnumerationLabel___redArg___closed__0_once, _init_lp_vsr_x2dveil_Smoke_instEnumerationLabel___redArg___closed__0);
v___f_1166_ = lean_alloc_closure((void*)(lp_vsr_x2dveil_Smoke_instEnumerationLabel___redArg___lam__0), 2, 1);
lean_closure_set(v___f_1166_, 0, v___x_1165_);
return v___f_1166_;
}
}
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instEnumerationLabel___redArg(lean_object* v_inst_1167_){
_start:
{
lean_object* v___f_1168_; lean_object* v___x_1169_; lean_object* v___x_1170_; 
v___f_1168_ = lean_obj_once(&lp_vsr_x2dveil_Smoke_instEnumerationLabel___redArg___closed__1, &lp_vsr_x2dveil_Smoke_instEnumerationLabel___redArg___closed__1_once, _init_lp_vsr_x2dveil_Smoke_instEnumerationLabel___redArg___closed__1);
v___x_1169_ = lean_box(0);
v___x_1170_ = l_List_mapTR_loop___redArg(v___f_1168_, v_inst_1167_, v___x_1169_);
return v___x_1170_;
}
}
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instEnumerationLabel(lean_object* v_node_1171_, lean_object* v_inst_1172_){
_start:
{
lean_object* v___x_1173_; 
v___x_1173_ = lp_vsr_x2dveil_Smoke_instEnumerationLabel___redArg(v_inst_1172_);
return v___x_1173_;
}
}
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instFinEncodableInjOnlyLabel___redArg___lam__0(lean_object* v_encode_1174_, lean_object* v_a_1175_){
_start:
{
lean_object* v___x_1176_; 
v___x_1176_ = lean_apply_1(v_encode_1174_, v_a_1175_);
return v___x_1176_;
}
}
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instFinEncodableInjOnlyLabel___redArg(lean_object* v_inst_1177_){
_start:
{
lean_object* v_card_1178_; lean_object* v_encode_1179_; lean_object* v___x_1181_; uint8_t v_isShared_1182_; uint8_t v_isSharedCheck_1187_; 
v_card_1178_ = lean_ctor_get(v_inst_1177_, 0);
v_encode_1179_ = lean_ctor_get(v_inst_1177_, 1);
v_isSharedCheck_1187_ = !lean_is_exclusive(v_inst_1177_);
if (v_isSharedCheck_1187_ == 0)
{
v___x_1181_ = v_inst_1177_;
v_isShared_1182_ = v_isSharedCheck_1187_;
goto v_resetjp_1180_;
}
else
{
lean_inc(v_encode_1179_);
lean_inc(v_card_1178_);
lean_dec(v_inst_1177_);
v___x_1181_ = lean_box(0);
v_isShared_1182_ = v_isSharedCheck_1187_;
goto v_resetjp_1180_;
}
v_resetjp_1180_:
{
lean_object* v___f_1183_; lean_object* v___x_1185_; 
v___f_1183_ = lean_alloc_closure((void*)(lp_vsr_x2dveil_Smoke_instFinEncodableInjOnlyLabel___redArg___lam__0), 2, 1);
lean_closure_set(v___f_1183_, 0, v_encode_1179_);
if (v_isShared_1182_ == 0)
{
lean_ctor_set(v___x_1181_, 1, v___f_1183_);
v___x_1185_ = v___x_1181_;
goto v_reusejp_1184_;
}
else
{
lean_object* v_reuseFailAlloc_1186_; 
v_reuseFailAlloc_1186_ = lean_alloc_ctor(0, 2, 0);
lean_ctor_set(v_reuseFailAlloc_1186_, 0, v_card_1178_);
lean_ctor_set(v_reuseFailAlloc_1186_, 1, v___f_1183_);
v___x_1185_ = v_reuseFailAlloc_1186_;
goto v_reusejp_1184_;
}
v_reusejp_1184_:
{
return v___x_1185_;
}
}
}
}
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instFinEncodableInjOnlyLabel(lean_object* v_node_1188_, lean_object* v_inst_1189_){
_start:
{
lean_object* v___x_1190_; 
v___x_1190_ = lp_vsr_x2dveil_Smoke_instFinEncodableInjOnlyLabel___redArg(v_inst_1189_);
return v___x_1190_;
}
}
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instInhabitedLabel_default___redArg(lean_object* v_inst_1191_){
_start:
{
lean_inc(v_inst_1191_);
return v_inst_1191_;
}
}
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instInhabitedLabel_default___redArg___boxed(lean_object* v_inst_1192_){
_start:
{
lean_object* v_res_1193_; 
v_res_1193_ = lp_vsr_x2dveil_Smoke_instInhabitedLabel_default___redArg(v_inst_1192_);
lean_dec(v_inst_1192_);
return v_res_1193_;
}
}
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instInhabitedLabel_default(lean_object* v_node_1194_, lean_object* v_inst_1195_){
_start:
{
lean_inc(v_inst_1195_);
return v_inst_1195_;
}
}
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instInhabitedLabel_default___boxed(lean_object* v_node_1196_, lean_object* v_inst_1197_){
_start:
{
lean_object* v_res_1198_; 
v_res_1198_ = lp_vsr_x2dveil_Smoke_instInhabitedLabel_default(v_node_1196_, v_inst_1197_);
lean_dec(v_inst_1197_);
return v_res_1198_;
}
}
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instInhabitedLabel___redArg(lean_object* v_inst_1199_){
_start:
{
lean_inc(v_inst_1199_);
return v_inst_1199_;
}
}
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instInhabitedLabel___redArg___boxed(lean_object* v_inst_1200_){
_start:
{
lean_object* v_res_1201_; 
v_res_1201_ = lp_vsr_x2dveil_Smoke_instInhabitedLabel___redArg(v_inst_1200_);
lean_dec(v_inst_1200_);
return v_res_1201_;
}
}
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instInhabitedLabel(lean_object* v_a_1202_, lean_object* v_inst_1203_){
_start:
{
lean_inc(v_inst_1203_);
return v_inst_1203_;
}
}
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instInhabitedLabel___boxed(lean_object* v_a_1204_, lean_object* v_inst_1205_){
_start:
{
lean_object* v_res_1206_; 
v_res_1206_ = lp_vsr_x2dveil_Smoke_instInhabitedLabel(v_a_1204_, v_inst_1205_);
lean_dec(v_inst_1205_);
return v_res_1206_;
}
}
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_ActionTag__IndT_toCtorIdx(lean_object* v_x_1207_){
_start:
{
lean_object* v___x_1208_; 
v___x_1208_ = lean_unsigned_to_nat(0u);
return v___x_1208_;
}
}
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_ActionTag__IndT_ofNat(lean_object* v_n_1209_){
_start:
{
lean_object* v___x_1210_; 
v___x_1210_ = lean_box(0);
return v___x_1210_;
}
}
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_ActionTag__IndT_ofNat___boxed(lean_object* v_n_1211_){
_start:
{
lean_object* v_res_1212_; 
v_res_1212_ = lp_vsr_x2dveil_Smoke_ActionTag__IndT_ofNat(v_n_1211_);
lean_dec(v_n_1211_);
return v_res_1212_;
}
}
LEAN_EXPORT uint8_t lp_vsr_x2dveil_Smoke_instDecidableEqActionTag__IndT(lean_object* v_x_1213_, lean_object* v_y_1214_){
_start:
{
uint8_t v___x_1215_; 
v___x_1215_ = 1;
return v___x_1215_;
}
}
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instDecidableEqActionTag__IndT___boxed(lean_object* v_x_1216_, lean_object* v_y_1217_){
_start:
{
uint8_t v_res_1218_; lean_object* v_r_1219_; 
v_res_1218_ = lp_vsr_x2dveil_Smoke_instDecidableEqActionTag__IndT(v_x_1216_, v_y_1217_);
v_r_1219_ = lean_box(v_res_1218_);
return v_r_1219_;
}
}
static lean_object* _init_lp_vsr_x2dveil_Smoke_instInhabitedActionTag__IndT_default(void){
_start:
{
lean_object* v___x_1220_; 
v___x_1220_ = lean_box(0);
return v___x_1220_;
}
}
static lean_object* _init_lp_vsr_x2dveil_Smoke_instInhabitedActionTag__IndT(void){
_start:
{
lean_object* v___x_1221_; 
v___x_1221_ = lean_box(0);
return v___x_1221_;
}
}
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instReprActionTag__IndT___lam__0(lean_object* v_____veil__x_1224_, lean_object* v_x_1225_){
_start:
{
lean_object* v___x_1226_; 
v___x_1226_ = ((lean_object*)(lp_vsr_x2dveil_Smoke_instReprActionTag__IndT___lam__0___closed__0));
return v___x_1226_;
}
}
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instReprActionTag__IndT___lam__0___boxed(lean_object* v_____veil__x_1227_, lean_object* v_x_1228_){
_start:
{
lean_object* v_res_1229_; 
v_res_1229_ = lp_vsr_x2dveil_Smoke_instReprActionTag__IndT___lam__0(v_____veil__x_1227_, v_x_1228_);
lean_dec(v_x_1228_);
return v_res_1229_;
}
}
static lean_object* _init_lp_vsr_x2dveil_Smoke_instToJsonActionTag__IndT___lam__0___closed__0(void){
_start:
{
lean_object* v___x_1232_; lean_object* v___x_1233_; lean_object* v___x_1234_; lean_object* v___x_1235_; 
v___x_1232_ = lean_unsigned_to_nat(0u);
v___x_1233_ = lean_unsigned_to_nat(120u);
v___x_1234_ = ((lean_object*)(lp_vsr_x2dveil_Smoke_instReprActionTag__IndT___lam__0___closed__0));
v___x_1235_ = l_Std_Format_pretty(v___x_1234_, v___x_1233_, v___x_1232_, v___x_1232_);
return v___x_1235_;
}
}
static lean_object* _init_lp_vsr_x2dveil_Smoke_instToJsonActionTag__IndT___lam__0___closed__1(void){
_start:
{
lean_object* v___x_1236_; lean_object* v___x_1237_; 
v___x_1236_ = lean_obj_once(&lp_vsr_x2dveil_Smoke_instToJsonActionTag__IndT___lam__0___closed__0, &lp_vsr_x2dveil_Smoke_instToJsonActionTag__IndT___lam__0___closed__0_once, _init_lp_vsr_x2dveil_Smoke_instToJsonActionTag__IndT___lam__0___closed__0);
v___x_1237_ = lean_alloc_ctor(3, 1, 0);
lean_ctor_set(v___x_1237_, 0, v___x_1236_);
return v___x_1237_;
}
}
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instToJsonActionTag__IndT___lam__0(lean_object* v_x_1238_){
_start:
{
lean_object* v___x_1239_; 
v___x_1239_ = lean_obj_once(&lp_vsr_x2dveil_Smoke_instToJsonActionTag__IndT___lam__0___closed__1, &lp_vsr_x2dveil_Smoke_instToJsonActionTag__IndT___lam__0___closed__1_once, _init_lp_vsr_x2dveil_Smoke_instToJsonActionTag__IndT___lam__0___closed__1);
return v___x_1239_;
}
}
static lean_object* _init_lp_vsr_x2dveil_Smoke_instActionTag__EnumClassActionTag__IndT(void){
_start:
{
lean_object* v___x_1242_; 
v___x_1242_ = lean_box(0);
return v___x_1242_;
}
}
LEAN_EXPORT uint64_t lp_vsr_x2dveil_Smoke_instHashableActionTag__IndT_hash(lean_object* v_x_1243_){
_start:
{
uint64_t v___x_1244_; 
v___x_1244_ = 0ULL;
return v___x_1244_;
}
}
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instHashableActionTag__IndT_hash___boxed(lean_object* v_x_1245_){
_start:
{
uint64_t v_res_1246_; lean_object* v_r_1247_; 
v_res_1246_ = lp_vsr_x2dveil_Smoke_instHashableActionTag__IndT_hash(v_x_1245_);
v_r_1247_ = lean_box_uint64(v_res_1246_);
return v_r_1247_;
}
}
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instFinEncodableActionTag__IndT___lam__0(lean_object* v_x_1256_){
_start:
{
lean_object* v___x_1257_; 
v___x_1257_ = lean_unsigned_to_nat(0u);
return v___x_1257_;
}
}
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instFinEncodableActionTag__IndT___lam__1(lean_object* v___x_1258_, lean_object* v_x_1259_){
_start:
{
lean_object* v___x_1260_; 
v___x_1260_ = l_List_get___redArg(v___x_1258_, v_x_1259_);
return v___x_1260_;
}
}
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_instFinEncodableActionTag__IndT___lam__1___boxed(lean_object* v___x_1261_, lean_object* v_x_1262_){
_start:
{
lean_object* v_res_1263_; 
v_res_1263_ = lp_vsr_x2dveil_Smoke_instFinEncodableActionTag__IndT___lam__1(v___x_1261_, v_x_1262_);
lean_dec(v___x_1261_);
return v_res_1263_;
}
}
static lean_object* _init_lp_vsr_x2dveil_Smoke_instFinEncodableActionTag__IndT___closed__2(void){
_start:
{
lean_object* v___x_1267_; lean_object* v___x_1268_; 
v___x_1267_ = ((lean_object*)(lp_vsr_x2dveil_Smoke_ActionTag__IndT_enumList));
v___x_1268_ = l_List_lengthTR___redArg(v___x_1267_);
return v___x_1268_;
}
}
static lean_object* _init_lp_vsr_x2dveil_Smoke_instFinEncodableActionTag__IndT___closed__4(void){
_start:
{
lean_object* v___x_1272_; lean_object* v___x_1273_; lean_object* v___x_1274_; 
v___x_1272_ = ((lean_object*)(lp_vsr_x2dveil_Smoke_instFinEncodableActionTag__IndT___closed__3));
v___x_1273_ = lean_obj_once(&lp_vsr_x2dveil_Smoke_instFinEncodableActionTag__IndT___closed__2, &lp_vsr_x2dveil_Smoke_instFinEncodableActionTag__IndT___closed__2_once, _init_lp_vsr_x2dveil_Smoke_instFinEncodableActionTag__IndT___closed__2);
v___x_1274_ = lean_alloc_ctor(0, 2, 0);
lean_ctor_set(v___x_1274_, 0, v___x_1273_);
lean_ctor_set(v___x_1274_, 1, v___x_1272_);
return v___x_1274_;
}
}
static lean_object* _init_lp_vsr_x2dveil_Smoke_instFinEncodableActionTag__IndT(void){
_start:
{
lean_object* v___x_1275_; 
v___x_1275_ = lean_obj_once(&lp_vsr_x2dveil_Smoke_instFinEncodableActionTag__IndT___closed__4, &lp_vsr_x2dveil_Smoke_instFinEncodableActionTag__IndT___closed__4_once, _init_lp_vsr_x2dveil_Smoke_instFinEncodableActionTag__IndT___closed__4);
return v___x_1275_;
}
}
static lean_object* _init_lp_vsr_x2dveil_Smoke_instOrdActionTag__IndT___closed__0(void){
_start:
{
lean_object* v___x_1276_; lean_object* v___f_1277_; 
v___x_1276_ = lp_vsr_x2dveil_Smoke_instFinEncodableActionTag__IndT;
v___f_1277_ = lean_alloc_closure((void*)(lp_veil_Veil_Ord_ofFinEncodable___redArg___lam__0___boxed), 3, 1);
lean_closure_set(v___f_1277_, 0, v___x_1276_);
return v___f_1277_;
}
}
static lean_object* _init_lp_vsr_x2dveil_Smoke_instOrdActionTag__IndT(void){
_start:
{
lean_object* v___f_1278_; 
v___f_1278_ = lean_obj_once(&lp_vsr_x2dveil_Smoke_instOrdActionTag__IndT___closed__0, &lp_vsr_x2dveil_Smoke_instOrdActionTag__IndT___closed__0_once, _init_lp_vsr_x2dveil_Smoke_instOrdActionTag__IndT___closed__0);
return v___f_1278_;
}
}
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_NextAct___redArg(lean_object* v_00_u03c7__rep_1279_, lean_object* v_00_u03c3__sub_1280_, lean_object* v_00_u03c1__sub_1281_, lean_object* v_elect__dec__0_1282_, lean_object* v_label_1283_){
_start:
{
lean_object* v___x_1284_; 
v___x_1284_ = lp_vsr_x2dveil_Smoke_elect_ext___redArg(v_00_u03c7__rep_1279_, v_00_u03c3__sub_1280_, v_00_u03c1__sub_1281_, v_elect__dec__0_1282_, v_label_1283_);
return v___x_1284_;
}
}
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_NextAct(lean_object* v_00_u03c1_1285_, lean_object* v_00_u03c3_1286_, lean_object* v_node_1287_, lean_object* v_node__dec__eq_1288_, lean_object* v_node__inhabited_1289_, lean_object* v_00_u03c7_1290_, lean_object* v_00_u03c7__rep_1291_, lean_object* v_00_u03c7__rep__lawful_1292_, lean_object* v_00_u03c3__sub_1293_, lean_object* v_00_u03c1__sub_1294_, lean_object* v_elect__dec__0_1295_, lean_object* v_label_1296_){
_start:
{
lean_object* v___x_1297_; 
v___x_1297_ = lp_vsr_x2dveil_Smoke_elect_ext___redArg(v_00_u03c7__rep_1291_, v_00_u03c3__sub_1293_, v_00_u03c1__sub_1294_, v_elect__dec__0_1295_, v_label_1296_);
return v___x_1297_;
}
}
LEAN_EXPORT lean_object* lp_vsr_x2dveil_Smoke_NextAct___boxed(lean_object* v_00_u03c1_1298_, lean_object* v_00_u03c3_1299_, lean_object* v_node_1300_, lean_object* v_node__dec__eq_1301_, lean_object* v_node__inhabited_1302_, lean_object* v_00_u03c7_1303_, lean_object* v_00_u03c7__rep_1304_, lean_object* v_00_u03c7__rep__lawful_1305_, lean_object* v_00_u03c3__sub_1306_, lean_object* v_00_u03c1__sub_1307_, lean_object* v_elect__dec__0_1308_, lean_object* v_label_1309_){
_start:
{
lean_object* v_res_1310_; 
v_res_1310_ = lp_vsr_x2dveil_Smoke_NextAct(v_00_u03c1_1298_, v_00_u03c3_1299_, v_node_1300_, v_node__dec__eq_1301_, v_node__inhabited_1302_, v_00_u03c7_1303_, v_00_u03c7__rep_1304_, v_00_u03c7__rep__lawful_1305_, v_00_u03c3__sub_1306_, v_00_u03c1__sub_1307_, v_elect__dec__0_1308_, v_label_1309_);
lean_dec(v_node__inhabited_1302_);
lean_dec_ref(v_node__dec__eq_1301_);
return v_res_1310_;
}
}
lean_object* initialize_Init(uint8_t builtin);
lean_object* initialize_Init(uint8_t builtin);
lean_object* initialize_veil_Veil(uint8_t builtin);
static bool _G_initialized = false;
LEAN_EXPORT lean_object* initialize_vsr_x2dveil_Vsr_Smoke(uint8_t builtin) {
lean_object * res;
if (_G_initialized) return lean_io_result_mk_ok(lean_box(0));
_G_initialized = true;
res = initialize_Init(builtin);
if (lean_io_result_is_error(res)) return res;
lean_dec_ref(res);
res = initialize_Init(builtin);
if (lean_io_result_is_error(res)) return res;
lean_dec_ref(res);
res = initialize_veil_Veil(builtin);
if (lean_io_result_is_error(res)) return res;
lean_dec_ref(res);
lp_vsr_x2dveil_Smoke_instInhabitedInstantiation = _init_lp_vsr_x2dveil_Smoke_instInhabitedInstantiation();
lean_mark_persistent(lp_vsr_x2dveil_Smoke_instInhabitedInstantiation);
lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__127 = _init_lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__127();
lean_mark_persistent(lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__127);
lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__129 = _init_lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__129();
lean_mark_persistent(lp_vsr_x2dveil___private_Vsr_Smoke_0____auto__129);
lp_vsr_x2dveil_Smoke_instInhabitedActionTag__IndT_default = _init_lp_vsr_x2dveil_Smoke_instInhabitedActionTag__IndT_default();
lean_mark_persistent(lp_vsr_x2dveil_Smoke_instInhabitedActionTag__IndT_default);
lp_vsr_x2dveil_Smoke_instInhabitedActionTag__IndT = _init_lp_vsr_x2dveil_Smoke_instInhabitedActionTag__IndT();
lean_mark_persistent(lp_vsr_x2dveil_Smoke_instInhabitedActionTag__IndT);
lp_vsr_x2dveil_Smoke_instActionTag__EnumClassActionTag__IndT = _init_lp_vsr_x2dveil_Smoke_instActionTag__EnumClassActionTag__IndT();
lean_mark_persistent(lp_vsr_x2dveil_Smoke_instActionTag__EnumClassActionTag__IndT);
lp_vsr_x2dveil_Smoke_instFinEncodableActionTag__IndT = _init_lp_vsr_x2dveil_Smoke_instFinEncodableActionTag__IndT();
lean_mark_persistent(lp_vsr_x2dveil_Smoke_instFinEncodableActionTag__IndT);
lp_vsr_x2dveil_Smoke_instOrdActionTag__IndT = _init_lp_vsr_x2dveil_Smoke_instOrdActionTag__IndT();
lean_mark_persistent(lp_vsr_x2dveil_Smoke_instOrdActionTag__IndT);
return lean_io_result_mk_ok(lean_box(0));
}
#ifdef __cplusplus
}
#endif
